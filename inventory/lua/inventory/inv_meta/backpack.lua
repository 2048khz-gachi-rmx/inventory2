local bp = Inventory.Inventories.Backpack or Emitter:extend()
Inventory.Inventories.Backpack = bp
_G.bp = bp
bp.IsInventory = true

bp.Name = "Backpack"
bp.SQLName = "ply_tempinv"
bp.NetworkID = 1
bp.MaxItems = 20

function bp:OnExtend(new_inv)
	new_inv.SQLName = false 	--set these yourself!!
	new_inv.NetworkID = false
	new_inv.Name = "unnamed inventory!?"
end

function bp:Initialize(ply)
	self.Items = {}
	self.Slots = {}

	if ply then
		self:SetOwner(ply)
		if SERVER then Inventory.MySQL.FetchPlayerItems(self, ply) end
	end
end

function bp:SetOwner(ply)
	self.Owner = ply
	self.OwnerSID = ply:SteamID64()
end

function bp:GetItemInSlot(slot)
	return self.Slots[slot]
end

function bp:AddItem(it)
	if not self.Slots then print("WHAT!??!?!") return end
	self.Items[it:GetUID()] = it
	self.Slots[it:GetSlot()] = it

	it.Inventory = self

	self:Emit("AddItem", it, it:GetUID())
end

function bp:GetFreeSlot()

	for i=1, self.MaxItems do
		if not self.Slots[i] then
			return i
		end
	end

end

function bp:SerializeItems(just_return)
	local max_uid = 0
	local max_id = 0
	local amt = 0

	for k,v in pairs(self:GetItems()) do
		max_uid = math.max(max_uid, v:GetUID())
		max_id = math.max(max_id, v:GetIID())
		amt = amt + 1
	end

	local ns = Inventory.Networking.NetStack(max_uid, max_id)

	ns:WriteUInt(self.NetworkID, 16)
	ns:WriteUInt(amt, 16)

	for k,v in pairs(self:GetItems()) do
		v:Serialize(ns)
	end

	return ns
end

function bp:NewItem(iid, cb, slot)

	slot = slot or self:GetFreeSlot()
	if not slot or slot > self.MaxItems then errorf("Didn't find a slot where to put the item or it was above MaxItems! (%s > %d)", slot, self.MaxItems) return end

	local it = Inventory.NewItem(iid, self, cb)
	it:SetSlot(slot)
	it:Insert(self)

	if it:GetUID() then
		self:AddItem(it)
	else
		it:On("AssignUID", function() self:AddItem(it) end)
	end
end

function bp:Register()
	hook.Run("InventoryTypeRegistered", self, self.Name)
	Inventory.Networking.InventoryIDs[self.NetworkID] = self
end

ChainAccessor(bp, "Items", "Items")
ChainAccessor(bp, "OwnerSID", "OwnerID")
ChainAccessor(bp, "OwnerSID", "OwnerSID")

if not Inventory.BackpackRegistered then
	hook.Add("OnInventoryLoad", "RegisterBackpack", function()
		bp:Register()
		Inventory.BackpackRegistered = true
	end)
	Inventory.BackpackRegistered = true
else
	bp:Register()
end
