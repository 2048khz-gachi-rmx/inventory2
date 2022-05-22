local it = Inventory.ItemObjects.Generic

function it:WriteNetworkedVars(ns, typ)
	local base = self:GetBaseItem()

	for k,v in ipairs(base.NetworkedVars) do

		--for every custom-encoded var, there is a bool written before the actual content
		--was the data even written or nah? did it exist, or did the function return anything?
		--if nah, the decoder will skip this particular var

		if isfunction(v.what) then
			local ret = v.what(self, true) --true means write, false means read
			if not IsNetStack(ret) then
				ns:WriteBool(false).PacketName = "Lack of function ret NWVar - " .. v.id
				errorNHf("NWVar %d (%s) didnt return netstack!", k, v.id)
				continue
			end

			ns:WriteBool(true).PacketName = "Has NetworkedVar - function: " .. tostring(self)
			ret:MergeInto(ns)
		else
			if not self.Data[v.what] or
				(typ ~= INV_NETWORK_FULLUPDATE and self.LastNetworkedVars[v.what] == self.Data[v.what]) then
				local why = not self.Data[v.what] and "(not set)"
					or "(already networked before: " .. self.LastNetworkedVars[v.what] .. ")"

				ns:WriteBool(false).PacketName = "Lack of predefined NWVar - " .. v.what .. " " .. why
				continue
			end

			ns:WriteBool(true).PacketName = "Has NWVar - predefined"

			ns["Write" .. v.type] (ns, self.Data[v.what], unpack(v.args)).PacketName = "NWVar - " .. v.what
			--self.LastNetworkedVars[v.what] = self.Data[v.what]
		end
	end
end

function it:Serialize(ns, typ)
	ns = ns or Inventory.Networking.NetStack()

	ns:WriteIDs(self)
	ns:WriteSlot(self)

	self:WriteNetworkedVars(ns, typ)
	return ns
end

function it:AssignInventory(inv, slot)
	if not inv then
		inv = self:GetInventory() or errorf("No inventory for the item to use for assigning! %s", self)
	end

	if not slot then
		slot = self:GetSlot()
		if not slot then
			errorf("No slot provided to insert the item into! %s", self)
			return
		end
	end

	local sid = invobj and invobj:GetOwnerID()

	local em = Inventory.MySQL.SetInventory(self, inv, slot)

	em:Then(print, print)
	self:SetInventory(inv)
	self:SetSlot(slot)

	return em
end

-- Stick the item into inventory SQL automatically
function it:Insert(invobj, cb)
	if not invobj then
		invobj = self.Inventory or errorf("No inventory for the item to use for inserting! %s", self)
		return
	end

	--local isql = invobj and invobj.SQLName

	local sid = invobj and invobj:GetOwnerID()

	local qobj = Inventory.MySQL.NewInventoryItem(self, invobj, sid)
	if not qobj then return end

	qobj:Then(function(_, query, dat)
		if cb then cb(self, uid) end

		--[[if not invobj:HasItem(self) then
			invobj:AddItem(self)
		end]]
	end)

	return qobj
end

-- Deserialize data from SQL (JSON)
function it:DeserializeData(dat)
	if not dat then return end

	local t = util.JSONToTable(dat)
	self.Data = t
end

--takes either a table of data to merge in
-- (for example: .Data  = {a = 2, b = 4} ; given = {a = 3, c = 5})
-- (result: .Data = {a = 3, b = 4, c = 5})

-- or a key-value pair

function it:RequiresRenetwork(inv)
	--[[for k,v in pairs(self.Changes[v]) do
		if Inventory.RequiresNetwork[k] then
			req = true
			break
		end
	end]]
	if not self:GetKnown() then return true end


	self.Changes = self.Changes or {}
	for k,v in pairs(self.Changes) do
		if Inventory.RequiresNetwork[k] then
			return true
		end
	end

	return false
end

function it:ResetChanges()
	self.Changes = {}
end

function it:AddChange(typ)
	self.Changes = self.Changes or {}
	self.Changes[typ] = true

	local inv = self:GetInventory()

	if inv then
		inv:AddChange(self, typ)
	end
end

function it:SetData(k, v)
	self:AddChange(INV_ITEM_DATACHANGED)

	if istable(k) then
		for k2,v2 in pairs(k) do
			self.Data[k2] = v2
		end
		--return Inventory.MySQL.ItemSetData(self, k)
		self.IPersistence:SaveData(k)
		return
	elseif not k or not v then
		errorf("it:SetData: expected table as arg #1 or key/value as #2 and #3: got %s, %s instead", type(k), type(v)) 
		return
	end

	self.Data[k] = v
	self.IPersistence:SaveData(k, v)
end

ChainAccessor(it, "SQLExists", "SQLExists")

function it:InitializeNew() end
function it:InitializeExisting() end