
local ms = Inventory.MySQL

local db = ms.DB

local qerr = function(self, err, q)
	ms.LogError("\n	Query: '%s'\n	Error: '%s'\n 	Trace: %s", q, err, debug.traceback("", 2))
end

local trerr = function(tr, err)
	local qs = tr:getQueries()
	local errs = {}
	for k,v in ipairs(qs) do
		local err = v:error()
		errs[#errs + 1] = (#err > 1 and err) or "[no error]"
	end
	ms.LogError("\n	Transaction error: '%s'\n Errors: %s \n Trace: %s", err, table.concat(errs, ";\n"), debug.traceback("", 2))
end

_G.IQError = qerr

local log = ms.Log

local create_table_query = [[
CREATE TABLE IF NOT EXISTS %s (
  `uid` INT NOT NULL,
  `puid` BIGINT UNSIGNED NULL,
%s]] --[[if the inventory uses slots, this will be '`slotid` MEDIUMINT UNSIGNED NULL,']] .. [[
%s]] --[[additional columns]] .. [[
  PRIMARY KEY (`uid`),
  UNIQUE KEY `uid` (`uid`),
  %s]] --[[constraints n' other stuff]] .. [[
  CONSTRAINT FOREIGN KEY (`uid`) REFERENCES `items` (`uid`) ON DELETE CASCADE
)
]]

local slot_str = "`slotid` MEDIUMINT UNSIGNED NULL,"
local slot_constr = "UNIQUE KEY `uq_slot_puid` (`puid`,`slotid`),"

--tbl_name: mandatory, table name to create in MySQL
--use_slots: false to not create `slotid` column, optional
--more_columns: table of columns or a string, optional (see below for table structure)
--more_constraints: string of additional constraints to add, optional

--[[
column = {
	name = "slotid",
	type = "TEXT",
	attr = "NOT NULL", --additional attributes such as UNSIGNED or w/e

	unique = {"puid", "uid"} 	to create (`slotid`, `puid`, `uid`)
								OR: [unique = "puid"] to create (`slotid`, `puid`)
}
]]

function ms.CreateInventoryTable(tbl_name, use_slots, more_columns, more_constraints)
	local more = ""
	local constraints = ""

	if istable(more_columns) then

		local str = "`%s` %s,"

		for k,v in ipairs(more_columns) do
			local name, typ, attr = v.name, v.type, v.attr
			local uq = v.unique

			if attr then typ = typ .. " " .. attr end

			local qname = ("`%s`"):format(name)

			--`name` TYPE (MORE ATTRIBUTES?)
			local str = str:format(name, typ) .. "\n"


			if uq then --add a constraint to the end

				--unique constraints can be with the column itself and with others(to form unique pairs)
				--provide a table like {"puid", "slotid"} to form a unique pair
				--or anything else to just make the var itself unique

				--`pair` is the columns in [UNIQUE KEY `` (...)]

				local pair = ""

				if istable(uq) then
					pair = qname .. (#uq > 0 and "," or "")
					for k, col in ipairs(uq) do
						pair = pair .. ("`%s`"):format(col)
						if uq[k + 1] then
							pair = pair .. ","
						end
					end

				elseif isstring(uq) then
					 		--V ourselves
								--  V the string
					pair = ("`%s`, `%s`"):format(name, uq)
				elseif isbool(uq) then
					pair = qname
				end

				constraints = constraints .. ("UNIQUE KEY `uq_%s` (%s),\n"):format(k, pair)
			end

			more = more .. str
		end
	end

	use_slots = (use_slots ~= false)

	local q = create_table_query:format(tbl_name,
		use_slots and slot_str or "",
		more,
		(use_slots and slot_constr or "") .. constraints .. (more_constraints or "")
		)

	local qobj = ms.DB:query(q)

	qobj.onSuccess = function()
		log("Created table `%s` successfully!", tbl_name)
	end

	qobj.onError = qerr

	qobj:start()
end

hook.Add("InventoryTypeRegistered", "CreateInventoryTables", function(inv)
	if not inv.SQLName and inv.UseSQL then errorf("Inventory %s is missing an SQLName!", inv.Name) return end
	if not inv.UseSQL then return end

	ms.CreateInventoryTable(inv.SQLName, inv.UseSlots, inv.SQLColumns, inv.SQLConstraints)
end)



local selIDs = ms.DB:query("SELECT * FROM itemids")

selIDs.onSuccess = function(self, dat)

	local conv = Inventory.IDConversion

	local names = conv.ToID
	local ids = conv.ToName

	for k,v in ipairs(dat) do
		ids[v.id] = v.name
		names[v.name] = v.id
	end

	Inventory:Emit("ItemIDsReceived", ids, names)
	hook.Run("InventoryItemIDsReceived", ids, names)

	Inventory.MySQL.IDsReceived = true
end
selIDs.onError = qerr

selIDs:start()

local assign_query = ms.DB:prepare("SELECT GetBaseItemID(?) AS id;")

-- 'arg' provided for easy chaining
-- e.g. ms.AssignItemID(it.Name, it.SetUID, it)
-- 			is basically
-- 		ms.AssignItemID(it.Name, function(uid) it:SetUID(uid) end)

function ms.AssignItemID(name, cb, arg)
	local conv = Inventory.IDConversion

	local id_exists = conv.ToID[name]

	if id_exists then
		cb(arg or id_exists, arg and id_exists or nil)
		return
	end

	-- query MySQL to create a new ItemID
	local qobj = assign_query
	qobj:setString(1, name)
	--local qobj = db:query(q)

	qobj.onSuccess = function(self, dat)
		local id = dat[1].id
					--V stfu
		if cb then cb(arg or id, arg and id or nil) end

		conv.ToID[name] = id
		conv.ToName[id] = name

		Inventory:Emit("ItemIDAssigned", name, id)
		hook.Run("InventoryItemIDAssigned", name, id)
	end

	qobj.onError = qerr

	qobj:start()
end


local newitem_name_query 	= ms.DB:prepare("SELECT InsertByItemName(?) AS uid LIMIT 1;")
local newitem_inv_query 	= ms.DB:prepare("CALL InsertByItemNameInInventory(?, ?, ?, ?);")

local newitem_id_query 		= ms.DB:prepare("INSERT INTO items(iid) VALUES (?)")--; SELECT last_insert_id() AS uid;")
local newitem_idinv_query 	= ms.DB:prepare("CALL InsertByIDInInventory(?, ?, ?, ?);")

function ms.NewItem(item, inv, ply, cb)

	local qobj

	local invname = inv and (inv.SQLName)-- or errorf("Inventory.MySQL.NewItem: No SQLName for inventory %s!", inv.Name))
	local iid = item.ItemID or item.ItemName

	if not invname then
		if isstring(iid) then
			newitem_name_query:setString(1, iid)
			qobj = newitem_name_query
		else
			newitem_id_query:setNumber(1, iid)
			qobj = newitem_id_query
		end
	else
		local sid = (IsPlayer(ply) and ply:SteamID64()) or (isstring(ply) and ply) or errorf("Inventory.MySQL.NewItem: expected player or steamid64 as arg #3, got %q instead", type(ply))
		if isstring(iid) then
			newitem_inv_query:setString(1, iid)
			qobj = newitem_inv_query
		else
			newitem_idinv_query:setNumber(1, iid)
			qobj = newitem_idinv_query
		end

		qobj:setString(2, invname)
		qobj:setString(3, sid)

		local slot = item:GetSlot()
		if not slot then
			slot = inv:GetFreeSlot()
			--qobj:clearParameters()
			if not slot then errorf("Inventory.MySQL.NewItem: Expected a free slot for item %s, but got nuffin' instead", item) return end
			item:SetSlot(slot)
		end

		qobj:setNumber(4, slot)

	end

	--[[qobj.onSuccess = function(self, dat, e)
		local uid = dat[1].uid
		cb(uid)
	end

	qobj.onError = qerr]]

	local qem = MySQLEmitter(qobj, true):Catch(qerr)

	qem:Once("Success", "AssignData", function(_, dat)
		local uid = qobj:lastInsert()
		if uid == 0 then uid = dat[1].uid end
		local dat = item:GetPermaData()
		if not table.IsEmpty(dat) then
			ms.ItemWriteData(item, dat)
		end
	end)


	return qem
	--qobj:start()

end

local delete_query = ms.DB:prepare("DELETE FROM items WHERE uid = ?")

function ms.DeleteItem(it)
	delete_query:setNumber(1, (isnumber(it) and it) or it:GetUID())

	return MySQLEmitter(delete_query, true)
end

--accepts dat, where:
--[[
	{
		column_name = "value",
		...
	}
]]
function ms.SetInventory(it, inv, slot, dat)
	local t = ms.DB:createTransaction()

	local q1
	if it:GetInventory() then
		q1 = ("DELETE FROM %s WHERE uid = %s"):format(it:GetInventory().SQLName, it:GetUID())
	end

	local columns, values = inv.UseSlots and ", slotid" or "", (slot and ", " .. slot) or (inv.UseSlots and "NULL") or ""

	if dat then
		--we have more args on the way, add commas
		columns, values = columns .. ",", values .. ","
		for k,v in ipairs(dat) do
			columns = columns .. k
			values = values .. ms.DB:escape(v)
		end
	end

	local ow, owuid = inv:GetOwner()
	local puid = mysqloo.quote(ms.DB, owuid)
	local q2

	if it:GetUIDFake() then
		q2 = ("INSERT IGNORE INTO %s (puid%s) VALUES (%s, %s%s)"):format(inv.SQLName, columns, puid, values )
	else
		q2 = ("INSERT IGNORE INTO %s (uid, puid%s) VALUES (%s, %s%s)"):format(inv.SQLName, columns, it:GetUID(), puid, values )
	end

	local qo1 = db:query(q1)
	local qo2 = db:query(q2)

	print(q1, q2)
	t:addQuery(qo1)
	t:addQuery(qo2)

	return MySQLEmitter:new(t, true):Catch(trerr)
end


 																							 -- SQL inventory name | SteamID64 as an int
																							    --  V 			 	 V
local fetchitems_query 	= "SELECT its.iid, its.uid, its.data, inv.slotid FROM items its INNER JOIN %s inv ON puid = %s AND its.uid = inv.uid"

--mysqloo is fucking autistic so this can't be used as a prepared query :/

function ms.FetchPlayerItems(inv, ply)
	local tname = inv.SQLName
	if not tname or tname == "" then errorf("Inventory MUST have an SQLName attached to it!") end

	local query = fetchitems_query:format(ms.DB:escape(tname), ms.DB:escape(ply:SteamID64()))
	local q = ms.DB:query(query)

	q.onSuccess = function(self, dat)
		Inventory.Log("MySQL: Fetched info for %q's %q inventory; %d items", ply:Nick(), tname, #dat)

		for k,v in ipairs(dat) do
			local it = Inventory.Util.GetMeta(v.iid)
			if not it then ErrorNoHalt("Failed to reconstruct item with ItemID: " .. v.iid) continue end

			it = it:new(v.uid, v.iid)

			it:SetOwner(ply)
			it:SetSlot(v.slotid)
			it:DeserializeData(v.data)

			inv:AddItem(it, true)
		end

	end

	q.onError = qerr

	q:start()
end

local setslot_query = "UPDATE %s SET slotid = %d WHERE uid = %s"
function ms.SetSlot(it, inv)
	local slot = (IsItem(it) and it:GetSlot()) or (isnumber(it) and it)

	if not slot then errorf("Failed to get slot for item %s", it) return end

	if not inv then inv = it:GetInventory() end
	if not inv.SQLName then errorf("Failed to get SQLName for inventory %s", inv) return end

	local q = setslot_query:format(inv.SQLName, slot, it:GetUID())

	MySQLEmitter(ms.DB:query(q), true):Catch(qerr)

end

--local swapslots_query = ms.DB:prepare("CALL SwapItemSlots(?, ?, ?, ?)") --takes tablename, sid64, slot1 (number), slot2 (number)
--^ this is too woke, do not use it


--takes: tablename, swapping-uid, puid, slot1 (number - move from), slot2 (number - move to)

local function swapSlots(tname, uid, sid, slot1, slot2)
	local t = ms.DB:createTransaction()

	local q1 = ("UPDATE %s SET slotid = NULL WHERE uid = %s"):format(tname, uid)
	local q2 = ("UPDATE %s SET slotid = %s WHERE slotid = %d AND puid = %s"):format(tname, slot2, slot1, sid)
	local q3 = ("UPDATE %s SET slotid = %s WHERE uid = %s"):format(tname, slot1, uid)

	local qo1 = db:query(q1)
	local qo2 = db:query(q2)
	local qo3 = db:query(q3)

	t:addQuery(qo1)
	t:addQuery(qo2)
	t:addQuery(qo3)
	print(q1, "\n", q2, "\n", q3)
	return MySQLEmitter:new(t, true):Catch(trerr)

	--t:start()
end

function ms.SwitchSlots(it1, it2, inv)
	if not it2 then
		ms.SetSlot(it1, inv)
		return
	end

	if not inv and IsItem(it1) then
		inv = it1:GetInventory()
		if it2:GetInventory() ~= inv then
			errorf("Inventory.MySQL.SwitchSlots: can't switch slots of two items in different inventories! (1: %s, 2: %s)", inv, it2:GetInventory())
			return
		end

		if not IsInventory(inv) then
			error("Inventory.MySQL.SwitchSlots: both items didn't have an inventory and none was provided!", 2)
			return
		end
	end

	local invname = inv.SQLName
	if not invname then errorf("Inventory missing SQL name! %s", inv) return end

	local slot1 = IsItem(it1) and it1:GetSlot() or it1
	local slot2 = IsItem(it2) and it2:GetSlot() or it2
	local _, puid = inv:GetOwner()

	if isnumber(slot1) and isnumber(slot2) then
		return swapSlots(invname, it1:GetUID(), puid, slot1, slot2)
	else
		errorf("Inventory.MySQL.SwitchSlots: missing one of the slots for item1 or item2 (got: %s, %s)", slot1, slot2)
	end

end


local new_dat_query = ms.DB:prepare("UPDATE items SET data = ? WHERE uid = ?")

-- COMPLETELY overrides item data with new key-values
-- Accepts either a key-value as the second argument or automatically takes the item's .Data

function ms.ItemWriteData(it, data)
	data = data or it:GetData()
	local json = util.TableToJSON(data)

	new_dat_query:setString(1, json)
	new_dat_query:setNumber(2, it:GetUID())

	return MySQLEmitter(new_dat_query, true)
end

local patch_dat_query = ms.DB:prepare("UPDATE items SET data = JSON_MERGE_PATCH(IFNULL(data, '[]'), ?) WHERE uid = ?")

-- Merge the SQL data with provided table of key-values (the table will be JSON'd)

function ms.ItemSetData(it, t)
	t = t or it:GetData()

	local json = util.TableToJSON(t)
	if not json then errorf("Failed to get JSON from arg: %s", t) return end --?

	printf("ItemSetData: patching JSON %s", json)

	patch_dat_query:setString(1, json)
	patch_dat_query:setNumber(2, it:GetUID())

	return MySQLEmitter(patch_dat_query, true)
end