--don't construct item objects directly; use Inventory.NewItem instead


local inv = Inventory

local it = Inventory.ItemObjects.Generic or Emitter:extend()
it.ClassName = "Generic Item"
it.IsItem = true

Inventory.ItemObjects.Generic = it

it.__tostring = function(self)
	return ("%s '%s' | ItemID: %d, ItemUID: %d"):format(self.ClassName, self.ItemName, self.ItemID, self.ItemUID)
end

function it:Initialize(uid, iid)

	assert(iid, "ItemID must be provided when constructing an item object!")

	if isstring(iid) then --ItemName provided instead of ItemID
		self.ItemName = iid
		self.ItemID = Inventory.Util.ItemNameToID(iid)
	else
		self.ItemID = iid
		self.ItemName = Inventory.Util.ItemIDToName(iid)
	end

	self.ItemUID = uid
	self.Data = {}

	local base = Inventory.BaseItems[iid]
	if not base then
		errorf("Failed to find Base Item for Item: UID: %s, IID: %d", uid or "[none]", iid)
	end

end

function it:SetOwner(ply)
	self.Owner = ply
	self.OwnerUID = ply:SteamID64()
end

function it:Insert(invobj, cb)
	if not invobj then invobj = self.Inventory or errorf("No inventory for the item to use for inserting!") end

	--local isql = invobj and invobj.SQLName
	local sid = invobj and invobj:GetOwnerID()

	inv.MySQL.NewItem(self, invobj, sid, function(uid)
		if cb then cb(self, uid) end
		self:SetUID(uid)
		self:Emit("AssignUID", uid)
	end)
end

ChainAccessor(it, "ItemUID", "ItemUID")
ChainAccessor(it, "ItemUID", "UID")

ChainAccessor(it, "ItemID", "ItemID")
ChainAccessor(it, "ItemID", "IID")
ChainAccessor(it, "Known", "Known")

BaseItemAccessor(it, "Name", "Name")
BaseItemAccessor(it, "Name", "NiceName")

BaseItemAccessor(it, "Model", "Model")
BaseItemAccessor(it, "FOV", "FOV")
BaseItemAccessor(it, "CamOffset", "CamOffset")
BaseItemAccessor(it, "LookAng", "LookAng")

function it:GetBaseItem()
	return Inventory.BaseItems[self.ItemID]
end
it.GetBase = it.GetBaseItem


ChainAccessor(it, "Inventory", "Inventory")

function it:SetSlot(slot)
	self.Slot = slot
	local inv = self:GetInventory()
	if inv then
		inv:SetSlot(self, slot)
	end
end

function it:GetSlot()
	return self.Slot
end

--[[
	Creates a brand new item and waits until you stick it into SQL with all the stats necessary.
	Don't use this for creating items pulled from SQL!
]]

function Inventory.NewItem(iid, invobj, cb)
	local item = it:new(nil, iid)
	item.Inventory = invobj

	return item
end

function it:WriteNetworkedVars(ns)
	local base = self:GetBaseItem()
	for k,v in ipairs(base.NetworkedVars) do

		--for every custom-encoded var, there is a bool written before the actual content
		--was the data even written or nah? did it exist, or did the function return anything?
		--if nah, the decoder will skip this particular var

		if isfunction(v.type) then
			local ret = v.type(self, true) --true means write, false means read
			if not IsNetStack(ret) then ns:WriteBool(false) continue end

			ns:WriteBool(true)
			ret:MergeInto(ns)
		else
			if not self.Data[v.what] then ns:WriteBool(false) continue end

			ns:WriteBool(true)
			ns["Write" .. v.type] (ns, self.Data[v.what], unpack(v.args))
		end
	end
end

function it:Serialize(ns)
	if not ns then
		ns = Inventory.Networking.NetStack()
	end

	ns:WriteIDs(self)
	ns:WriteSlot(self)

	self:WriteNetworkedVars(ns)
	return ns
end

function it:ReadNetworkedVars()
	local base = self:GetBaseItem()

	for k,v in ipairs(base.NetworkedVars) do
		local read = net.ReadBool()
		if not read then continue end

		if isfunction(v.type) then
			v.type(self, false)
		else
			self.Data[v.what] = net["Read" .. v.type] (unpack(v.args))
		end
	end

end