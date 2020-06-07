local bp = Inventory.Inventories.Backpack or Emitter:extend()
Inventory.Inventories.Backpack = bp
_G.bp = bp
bp.IsInventory = true

bp.Name = "Backpack"
bp.SQLName = "ply_tempinv"
bp.NetworkID = 1
bp.MaxItems = 20

function bp:__tostring()
	return ("%s (owner: %s)"):format(
		self.Name,
		( IsValid(self.Owner) and tostring(self.Owner) .. ("[SID: %s] "):format(self.OwnerUID) ) 
			or self.OwnerUID
	)

end
function bp:OnExtend(new_inv)
	new_inv.SQLName = false 	--set these yourself!!
	new_inv.NetworkID = false
	new_inv.Name = "unnamed inventory!?"
end

function bp:Initialize(ply)
	self.Items = {}
	self.Slots = {}
	self.Changes = {}

	if ply then
		self:SetOwner(ply)
		if SERVER then Inventory.MySQL.FetchPlayerItems(self, ply) end
	end
end

function bp:SetOwner(ply)
	self.Owner = ply
	self.OwnerUID = ply:SteamID64()
end

function bp:GetOwner()
	return self.Owner, self.OwnerUID
end

function bp:SetSlot(it, slot)   --this is basically an accessor func;
								--it doesn't store the changes and doesn't check if an item exists there
								--use this when moving items as it will also write down the change
	for i=1, self.MaxItems do
		if self.Slots[i] == it then
			self.Slots[i] = nil
			--not breaking. just in case there's more.
		end
	end

	self.Slots[slot] = it

	if it:GetKnown() then self:AddChange(it, INV_ITEM_MOVED) end --if the player doesn't know about the item, don't replace the change
end

function bp:RemoveItem(it)
	local uid = ToUID(it)

	local its, slots = self:GetItems(), self:GetSlots()

	local foundit = its[uid]
	if not foundit then errorf("Tried to remove an item which didn't exist in the inventory in the first place!\nInventory: %s\nItem: %s\n", self, it) return end

	its[uid] = nil

	if foundit:GetSlot() then
		slots[foundit:GetSlot()] = nil
	else

		for i=1, self.MaxItems do
			if self.Slots[i] == foundit then
				self.Slots[i] = nil
			end
		end

	end

	if foundit:GetKnown() then self:AddChange(foundit, INV_ITEM_DELETED) else print("item wasn't even known!!!", foundit:GetUID()) self:AddChange(foundit, nil) end

	return foundit
end

function bp:DeleteItem(it)
	local uid = (isnumber(it) and it) or it:GetUID()

	local it = self:RemoveItem(it)

	if it:GetKnown() then self:AddChange(it, INV_ITEM_DELETED) else self:AddChange(it, nil) end --if the player doesn't know about the item, don't even tell him about the deletion
	if SERVER then Inventory.MySQL.DeleteItem(it) end

	return it
end

function bp:MoveItem(it, slot)	--this is a utility function which swaps slots if an item exists and stores the slot change in sql
	if self.MaxItems and slot > self.MaxItems then errorf("Attempted to move item out of inventory bounds (%d > %d)", slot, self.MaxItems) return end
	local it2 = self:GetItemInSlot(slot)
	local b4slot = it:GetSlot()
	print("bp:MoveItem: moved src:", b4slot, it:GetUID(), " into", slot)
	if it == it2 or it:GetSlot() == slot then return false end

	it:SetSlot(slot)
	if it2 then it2:SetSlot(b4slot) end

	if SERVER then return Inventory.MySQL.SwitchSlots(it, it2) end
end

function bp:GetItemInSlot(slot)
	return self.Slots[slot]
end

function bp:AddItem(it)
	if not self.Slots then print("WHAT!??!?!") return end
	self.Items[it:GetUID()] = it
	self.Slots[it:GetSlot()] = it
	self:AddChange(it, INV_ITEM_ADDED)

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

function bp:GetItem(uid)
	return self:GetItems()[uid]
end

function bp:HasItem(it)
	if IsItem(it) then
		return self:GetItem(it:GetUID())
	else
		return self:GetItem(it)
	end
end

function bp:Reset()
	table.Empty(self.Items)
	table.Empty(self.Slots)
end

function bp:HasAccess(ply, action)
	return ply == self:GetOwner()
end

--takes: item or uid, INV_ITEM_DELETED or INV_ITEM_MOVED
function bp:AddChange(it, what, nonetwork)
	self.Changes[it] = what
end

function bp:Register()
	hook.Run("InventoryTypeRegistered", self, self.Name)
	Inventory.Networking.InventoryIDs[self.NetworkID] = self
end

ChainAccessor(bp, "Items", "Items")
ChainAccessor(bp, "Slots", "Slots")
ChainAccessor(bp, "OwnerUID", "OwnerID")
ChainAccessor(bp, "OwnerUID", "OwnerUID")

if not Inventory.BackpackRegistered then

	hook.Add("OnInventoryLoad", "RegisterBackpack", function()
		if SERVER then include("inventory/inv_meta/backpack_sv_extension.lua") end
		bp:Register()

		Inventory.BackpackRegistered = true
	end)

	Inventory.BackpackRegistered = true
else

	if SERVER then include("inventory/inv_meta/backpack_sv_extension.lua") end
	bp:Register()

end


