util.AddNetworkString("Inventory")
util.AddNetworkString("InventoryConstants")

local PLAYER = FindMetaTable("Player")

Inventory.Networking = Inventory.Networking or {InventoryIDs = {}}
local nw = Inventory.Networking

local invnet = netstack:extend()
_G.invnet = invnet

local log = function(...) Inventory.Log(...) end

local names = {
	UsesUID = {
		" - ItemUID size",
		" - ItemUID"
	},
	UsesID = {
		" - ItemID size",
		" - ItemID"
	},
	Slot = " - Item Slot",
	InventoryNID = " - Inventory NetworkID",
	ItemsAmount = " - Amount of Inventory Items",

	HasDeleted = " - Has Deleted items",
	DeletionAmt = " - Amount of deleted items",

	HasMoved = " - Has Moved items",
	MovedAmt = " - Amount of moved items",

	HasCrossMoved = " - Has cross-inventory moved items",
	CrossMovedAmt = " - Amount of cross-inventory moved items"
}

local function getArgName(t)
	if t.PacketName then return t.PacketName end

	for k,v in pairs(names) do
		if t[k] then
			if istable(v) then
				return v[t[k]]
			else
				return v
			end
		end
	end
	return ""
end

invnet.__tostring = function(self)
	local head = "InvStack: %d ops:"
	head = head:format(#self.Ops)

	local args = ""

	for k,v in ipairs(self.Ops) do
		local argsstr = ""  --can't do `table.concat(v.args, ", ")` because it may have shit like userdata(entities) which table.concat doesn't like
		for k2,v2 in ipairs(v.args) do
			argsstr = argsstr .. tostring(v2) .. ", "
		end

		argsstr = argsstr:gsub("%.$", "")
		argsstr = argsstr .. getArgName(v)

		args = args .. ("%d: %s - %s\n"):format(k, v.type, argsstr)
	end

	args = args:sub(1, #args - 1)

	return head .. "\n" .. args
end

function invnet:Initialize(uid, iid)
	self.MaxUIDLen = (uid and bit.GetLen(uid)) or 32
	self.MaxIDLen = (iid  and bit.GetLen(iid)) or 32

	self.MaxUID = uid or 4294967296
	self.MaxID = iid or 4294967296

	self:WriteUInt(self.MaxUIDLen, 5).UsesUID = 1    --maximum bit size of a  UID in the queue
	self:WriteUInt(self.MaxIDLen, 5).UsesID = 1      --maximum bit size of an IID in the queue

end

function invnet:SetMaxIDs(uid, iid)

	if uid then
		self.MaxUID = uid
		local sz = bit.GetLen(uid)
		self:GetOps()[1].args[1] = sz
	end

	if iid then
		self.MaxUID = iid
		local sz = bit.GetLen(iid)
		self:GetOps()[1].args[1] = sz
	end
end

function invnet:UpdateSize()

	for k,v in ipairs(self.Ops) do
		if v.UsesUID then
			v.args[v.UsesUID] = self.MaxUIDLen
		elseif v.UsesID then
			v.args[v.UsesID] = self.MaxIDLen
		end
	end
end

local max = math.max

function invnet:Resize(...)
	local t

	if not select(2, ...) then  --given a table of items
		t = ...
	else
		t = {...}               --given items as args
	end

	local max_id, max_uid = 0, 0

	for k, it in ipairs(t) do
		if IsItem(it) then
			max_id = max(it:GetIID(), max_id)
			max_uid = max(it:GetUID(), max_uid)
		else --assuming UID
			max_uid = max(it, max_uid)
		end
	end

	local isz, usz = bit.GetLen(max_id), bit.GetLen(max_uid)

	self.MaxUID = max(self.MaxUID, max_uid)
	self.MaxID = max(self.MaxID, max_id)

	self.MaxUIDLen = max(usz, self.MaxUIDLen)
	self.MaxIDLen = max(isz, self.MaxIDLen)

	self:UpdateSize()
end

function invnet:WriteIDs(it)
	local uid, iid = it:GetUID(), it:GetIID()

	if uid > self.MaxUID then errorf("UID out of initialized range! (attempted to write: %d ; max. was: %d)", uid, self.MaxUID) end
	if iid > self.MaxID then errorf("IID out of initialized range! (attempted to write: %d ; max. was: %d)", iid, self.MaxID) end

	self:WriteUInt(uid, self.MaxUIDLen).UsesUID = 2
	self:WriteUInt(iid, self.MaxIDLen).UsesID = 2
end

function invnet:WriteUID(it)
	local uid = isnumber(it) and it or it:GetUID()

	if uid > self.MaxUID then errorf("UID out of initialized range! (attempted to write: %d ; max. was: %d)", uid, self.MaxUID) end
	local t = self:WriteUInt(uid, self.MaxUIDLen)
	t.UsesUID = 2
	return t
end

function invnet:WriteSlot(it)
	local len = it:GetInventory().MaxItems
	if len then
		len = bit.GetLen(len)
		local t = self:WriteUInt(it:GetSlot(), len)
		t.Slot = true
	end
end

function invnet:WriteInventory(inv)
	local id = inv.NetworkID
	if not id then errorf("Inventory %s doesn't have an NetworkID!", inv) return end

	self:WriteUInt(id, 8).InventoryNID = true
end

--provide ids as a table of {[itemID] = "itemName"} to only network that

local newItems = {}

function nw.NetworkItemNames(ply, ids)
	if istable(ply) and #ply == 0 then return end -- um

	log("Networking constants for %s", ply)

	if istable(ply) and IsPlayer(select(2, next(ply))) then
		for k,v in ipairs(ply) do
			ply.KnowsItemNames = true
		end
	elseif IsPlayer(ply) then
		ply.KnowsItemNames = true
	end

	local dat = von.serialize(ids or Inventory.IDConversion.ToName)
	local comp = util.Compress(dat)
	local needs_comp = false

	if #comp < #dat then
		needs_comp = true
		dat = comp
	end

	net.Start("InventoryConstants")
		net.WriteUInt(#dat, 16)
		net.WriteBool(needs_comp)
		net.WriteData(dat, #dat)
	net.Send(ply)

	log("SV-NW: Sent inventory constants to %s", IsPlayer(ply) and ply:Nick() or (#ply .. " players"))

	table.Empty(newItems)
end

timer.Simple(0.3, function()
	if Inventory.MySQL.IDsReceived then
		nw.NetworkItemNames(player.GetAll())
		UnionTable(player.GetAll()):NetworkInventory()
	else
		hook.Once("InventoryItemIDsReceived", "NetworkConstants", function()
			nw.NetworkItemNames(player.GetAll())
		end)
	end

	--add the event listener only after all the ID's were networked
	Inventory:On("ItemIDAssigned", "NetworkConstants", function(inv, name, id)
		newItems[id] = name

		timer.Create("InventoryNetworkConstants", 0.2, 1, function() -- give a time window to register all items to send them all off at once
			nw.NetworkItemNames(player.GetAll(), newItems)
			table.Empty(newItems)
		end)

	end)
end)

function nw.NetStack(uid, iid)
	local ns = invnet:new(uid, iid)
	return ns
end

nw.DebugNetworking = (nw.DebugNetworking ~= nil and false) or nw.DebugNetworking

function nw.SendNetStack(ns, ply)
	net.Start("Inventory")
		if nw.DebugNetworking then print(ns) end
		net.WriteNetStack(ns)
	net.Send(ply)
end

function nw.SendNetStacks(nses, ply)

	net.Start("Inventory")
		for k,v in ipairs(nses) do
			net.WriteNetStack(v)
			if nw.DebugNetworking then print(v) end
		end
	net.Send(ply)
end

function nw.WriteHeader(typ, invs, invOw, ply)
	local header = netstack:new()

	header:WriteUInt(typ, 4).NetworkType = true
	header:WriteUInt(invs, 8).InventoryAmt = true        --write amount of inventories we networked
	header:WriteEntity(invOw).InventoryOwner = true        --write the player whose inventories we're networking
	local tk


	if IsPlayer(ply) then
		tk = ply.InventoryNetworkToken
		--ply.InventoryNetworkToken = nil
	elseif istable(ply) then
		for k,v in ipairs(ply) do
			if v.InventoryNetworkToken then
				tk = v.InventoryNetworkToken
			end

			--v.InventoryNetworkToken = nil
		end
	end

	if tk then
		print("writing token", tk)
		header:WriteBool(true).HasToken = true
		header:WriteUInt(tk, 16).TokenID = true
	else
		header:WriteBool(false).HasToken = true
	end

	return header
end

local function knows(ply)
	return ply.KnowsItemNames
end

for k,v in ipairs(player.GetAll()) do
	v.KnowsItemNames = nil
end

function nw.NetworkInventory(ply, inv, typ, just_return, key) --mark 'just_return' as true for this function to just return an invnet (netstack) object
	if inv and IsInventory(inv) and not inv.NetworkID then errorf("Cannot send inventory %q as it doesn't have a network ID!", inv.Name) return end
	if typ == nil then typ = INV_NETWORK_FULLUPDATE end

	-- make sure they know the item enums
	if istable(ply) then
		nw.NetworkItemNames(Filter(ply, true):Invert(knows))
	elseif IsPlayer(ply) then
		if not knows(ply) then nw.NetworkItemNames(ply) end
	end

	hook.Run("InventoryNetwork", ply, inv)

	if IsInventory(inv) then
		inv:SetLastResync(CurTime()) -- track when we last resynced the inventory

		if inv.MultipleInstances and not key then 	-- if there can exist multiple instances of the same type of inventory
													-- then you need a key with which to differentiate which one it is
													-- if we weren't given one, we try to find it
			for k,v in pairs(inv:GetOwner().Inventory) do
				printf("searching: %p vs. %p", v, inv)
				if v == inv then
					key = k
					break
				end
			end
			if not key then errorf("Couldn't find key for inventory: %s", inv) return end
		end

		-- serialize this inventory's items into a netstack
		local ns = inv:SerializeItems(typ, key)
		nw.CurrentInventory = ns

		-- serialize inventory changes into the same netstack
		-- inventory changes = item moves, item deletions etc.
		if typ == INV_NETWORK_UPDATE then
			inv:WriteChanges(ns)
		end

		if just_return then
			return ns
		else 						--      V we're only networking 1 inventory
			local st = {nw.WriteHeader(typ, 1, inv:GetOwner(), ply), ns} --write the header first, then the actual contents

			nw.SendNetStacks(st, ply)
		end

	else -- no inventory was specified;
		 -- either it was a table of multiple inventories
		 -- or we're networking to the owner himself (meaning we network all their inventories)

		local invs = (istable(inv) and inv) or ply.Inventory
		--if we were given just a few inventories then it's most likely it's just an update
		if istable(inv) then typ = INV_NETWORK_UPDATE end

		local stacks = {}
		local owner

		-- recursively call this function for every inventory
		-- with `just_return` = true, so we get netstacks back
		for k,v in pairs(invs) do
			stacks[#stacks + 1] = nw.NetworkInventory(ply, v, typ, true, k)
			local iown = v:GetOwner()
			if owner and iown ~= owner then errorf("Cannot send multiple inventories with different owners in one net! (%s ~= %s)", owner, iown) return end
			owner = iown
			nw.CurrentInventory = nil
		end

		local header = nw.WriteHeader(typ, #stacks, owner, ply) -- write the header and then the stacks
		table.insert(stacks, 1, header)

		if just_return then
			return stacks
		else
			nw.SendNetStacks(stacks, ply)
		end
	end
end

PLAYER.NetworkInventory = nw.NetworkInventory
PLAYER.NI = nw.NetworkInventory

function nw.UpdateInventory(ply, inv)
	return nw.NetworkInventory(ply, inv, INV_NETWORK_UPDATE)
end

PLAYER.UpdateInventory = nw.UpdateInventory
PLAYER.UI = nw.UpdateInventory

function nw.SetToken(ply, tk)
	ply.InventoryNetworkToken = tk
	INVENTORY_CURRENTTOKEN = tk
end

function nw.GetToken(ply)
	return ply.InventoryNetworkToken
end

PLAYER.SetInventoryNWToken = nw.SetToken
PLAYER.GetInventoryNWToken = nw.GetToken

nw.ResyncCDs = nw.ResyncCDs or {}
nw.ResyncQueue = nw.ResyncQueue or {}

nw.UpdateCDs = nw.UpdateCDs or {}
nw.UpdateQueue = nw.UpdateQueue or {}

local resyncCDs = nw.ResyncCDs
local resyncCD = 3
local updateCD = 0.5


local function insInvs(t, v)
	if IsInventory(v) and not table.HasValue(t, v) then
		table.insert(t, v)
	elseif IsInventory(select(2, next(v))) then
		for k,v2 in pairs(v) do
			insInvs(t, v2)
		end
	end
end

function nw.RequestResync(ply, ...)
	resyncCDs[ply] = resyncCDs[ply] or CurTime() - (resyncCD + 1)

	nw.ResyncQueue[ply] = nw.ResyncQueue[ply] or {}

	local invs = {...}
	if #invs == 0 then
		invs = ply.Inventory
	end

	for k,v in ipairs(invs) do
		insInvs(nw.ResyncQueue[ply], v)
	end

	if CurTime() - resyncCDs[ply] < resyncCD then
		timer.Create( "ResyncInventory:" .. ply:SteamID64(), resyncCD - (CurTime() - resyncCDs[ply]), 1, function()
			nw.RequestResync(ply)
		end)
		return false
	end

	resyncCDs[ply] = CurTime()

	if #nw.ResyncQueue[ply] > 0 then
		for k,v in ipairs(nw.ResyncQueue[ply]) do
			ply:NetworkInventory(v)
		end
	else
		ply:NetworkInventory()
	end
end

function nw.RequestUpdate(ply, ...)
	nw.UpdateCDs[ply] = nw.UpdateCDs[ply] or CurTime() - (updateCD + 1)
	nw.UpdateQueue[ply] = nw.UpdateQueue[ply] or {}

	local invs = {...}
	if #invs == 0 then
		for k,v in pairs(ply.Inventory) do
			invs[#invs + 1] = v
		end
	end

	for k,v in ipairs(invs) do
		insInvs(nw.UpdateQueue[ply], v)
	end

	local tok = ply:GetInventoryNWToken()

	if CurTime() - nw.UpdateCDs[ply] < updateCD then
		timer.Create( "UpdateInventory:" .. ply:SteamID64(), updateCD - (CurTime() - nw.UpdateCDs[ply]), 1, function()
			if not ply:GetInventoryNWToken() then
				ply:SetInventoryNWToken(tok)
				print("put on cd token:", tok)
			end

			nw.RequestUpdate(ply)
			--ply:SetInventoryNWToken(nil)
		end)
		return false
	end

	nw.UpdateCDs[ply] = CurTime()

	if #nw.UpdateQueue[ply] > 0 then
		for k,v in ipairs(nw.UpdateQueue[ply]) do
			ply:UpdateInventory(v)
		end
	end
end

PLAYER.RequestUpdateInventory = nw.RequestUpdate
PLAYER.RequestUI = nw.RequestUpdate

function nw.ReadInventory()
	local ent = net.ReadEntity()
	local id = net.ReadUInt(16)

	if not ent or not IsValid(ent) then return false, "invalid entity" end

	local base = Inventory.Util.GetInventory(id)
	if not base then errorf("didn't find inventory with NWID: %s", id) return end

	if base.MultipleInstances then
		local key = net.ReadUInt(16)

		if not ent.Inventory[key] then errorf("didn't find inventory in the entity with NWID/key: %s/%s", id, key) return end
		return ent.Inventory[key]
	end

	for k,v in pairs(ent.Inventory) do
		if v.NetworkID == id then
			return v
		end
	end

	return false, "didnt find inventory in " .. tostring(ent)
end

function nw.ReadItem(inv)
	local uid = net.ReadUInt(32)

	local it = inv:GetItem(uid)
	if not it then return false, ("[%d] didn't find item UID %d in %s"):format(
		INVENTORY_CURRENTTOKEN or -1, uid, inv
		) end

	return it
end


hook.Add("PlayerFullyLoaded", "InventoryNetwork", function(ply)
	-- eh just let the player request the resync
	--nw.NetworkItemNames(ply)
	--nw.NetworkInventory(ply)
end)