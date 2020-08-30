local bp = Inventory.Inventories.Backpack or Emitter:extend()
Inventory.Inventories.Backpack = bp

bp.IsInventory = true

bp.Name = "Backpack"
bp.SQLName = "ply_tempinv"
bp.NetworkID = 1
bp.MaxItems = 20
bp.UseSlots = true

bp.UseSQL = true

bp.IsBackpack = true
bp.AutoFetchItems = true

function bp:__tostring()
	return ("%s (owner: %s)"):format(
		self.Name,
		( IsValid(self.Owner) and tostring(self.Owner) .. ("[SID: %s] "):format(self.OwnerUID) ) 
			or self.OwnerUIDx2
	)

end
function bp:OnExtend(new_inv)
	new_inv.SQLName = false 	--set these yourself!!
	new_inv.NetworkID = false
	new_inv.Name = "unnamed inventory!?"
	new_inv.IsBackpack = false
end

function bp:Initialize(ply)
	self.Items = {}
	self.Slots = {}
	self.Changes = {}

	if ply then
		self:SetOwner(ply)
		if SERVER and self.AutoFetchItems then
			Inventory.MySQL.FetchPlayerItems(self, ply)
		end
	end
end

function bp:LoadItems()
	if SERVER then Inventory.MySQL.FetchPlayerItems(self, self:GetOwner()) else error("This function isn't meant to be run clientside...") end
end

function bp:SetOwner(ply)
	self.Owner = ply
	if ply:IsPlayer() then self.OwnerUID = ply:SteamID64() end
	self:Emit("OwnerAssigned", ply)
end

function bp:GetOwner()
	return self.Owner, self.OwnerUID
end

function bp:SetSlot(it, slot)   --this is basically an accessor func;
								--it doesn't store the slot change in SQL and doesn't check if an item exists there
								--use this when moving items as it will also write down the change, use :MoveItem() when moving items within one inventory
								--item:SetSlot() is preferred
	for i=1, self.MaxItems do
		if self.Slots[i] == it then
			print("found past self @ slot", i, self.Slots[i]:GetAmount(), self.Slots[i]:GetUID())
			self.Slots[i] = nil
			--not breaking. just in case there's more.
		end
	end

	print("setting", it, "@", slot, "in", self)

	self.Slots[slot] = it

	if it:GetKnown() then self:AddChange(it, INV_ITEM_MOVED) end --if the player doesn't know about the item, don't replace the change
end

--suppresserror if you're not sure the change was predicted (e.g receiving networked deletions)
function bp:RemoveItem(it, suppresserror)
	--just removes an item from itself and networks the change
	--if CLIENT then printf("---------\nRemoveItem called clientside, removing from inv %s, slot %s : traceback: %s", self, IsItem(it) and it:GetSlot() or "[uid provided]", debug.traceback()) end

	local uid = ToUID(it)

	local its, slots = self:GetItems(), self:GetSlots()
	local foundit

	if uid then
		foundit = its[uid]
		its[uid] = nil
	else
		local found

		for k,v in pairs(its) do
			if v == it then
				its[k] = nil
				foundit = v
				break
			end
		end
	end

	if not foundit and not suppresserror then errorf("Tried to remove an item which didn't exist in the inventory in the first place!\nInventory: %s\nItem: %s\n", self, it) return end
	if not foundit then return end

	local slot = foundit:GetSlot()

	if slot then
		slots[slot] = nil
	else

		for i=1, self.MaxItems do
			if self.Slots[i] == foundit then
				self.Slots[i] = nil
				slot = i
			end
		end

	end

	foundit:SetInventory(nil)
	foundit:SetSlot(nil)

	--if the player doesn't know about the item, don't even tell him about the deletion
	if foundit:GetKnown() then self:AddChange(foundit, INV_ITEM_DELETED) else self.Changes[foundit] = nil end
	self:Emit("Change")
	self:Emit("RemovedItem", it, slot)
	return foundit
end

function bp:DeleteItem(it, suppresserror)
	--actually completely deletes an item, both from the backpack and from MySQL completely
	local uid = (isnumber(it) and it) or it:GetUID()

	local it = self:RemoveItem(it, suppresserror)

	if SERVER then Inventory.MySQL.DeleteItem(it) end
	self:Emit("Change")
	return it
end

function bp:IsSlotLegal(slot)
	return (not self.MaxItems and true) or slot <= self.MaxItems
end

function bp:MoveItem(it, slot)	--this is a utility function which swaps slots if an item exists and stores the slot change in sql
	if not self:IsSlotLegal(slot) then errorf("Attempted to move item out of inventory bounds (%d > %d)", slot, self.MaxItems) return end
	local it2 = self:GetItemInSlot(slot)
	local b4slot = it:GetSlot()

	if it == it2 or it:GetSlot() == slot then return false end

	it:SetSlot(slot)
	if it2 then it2:SetSlot(b4slot) end

	if SERVER then return Inventory.MySQL.SwitchSlots(it, it2) end
end

function bp:GetItemInSlot(slot)
	return self.Slots[slot]
end

function bp:AddItem(it, ignore_emitter)
	if not it:GetSlot() then errorf("Can't add an item without a slot set! Set a slot first!\nItem: %s", it) return end

	if it:GetInventory() and it:GetInventory() ~= self then
		errorf("Can't add an item that already has an inventory, remove it from the old inventory first!\nItem: %s\nItem's inv: %s\nAttempted inv: %s\n----\n", it, it:GetInventory(), self)
		return
	end

	if not ignore_emitter then
		local can = self:Emit("CanAddItem", it, it:GetUID())
		if can == false then return false end
	end

	if it:GetUID() then
		self.Items[it:GetUID()] = it
	else
		if table.HasValue(self.Items, it) then errorf("Trying to add an item which already existed in this inventory!") return end
		self.Items[#self.Items + 1] = it
		it:SetUID(#self.Items)
		it:SetUIDFake(true)
	end

	self.Slots[it:GetSlot()] = it
	self:AddChange(it, INV_ITEM_ADDED)

	it:SetInventory(self)

	self:Emit("AddItem", it, it:GetUID())
	self:Emit("Change")
	return it:GetSlot()
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
	local allow = self:Emit("Can" .. action, ply)
	if allow ~= nil then return allow end

	return ply == self:GetOwner()
end

--takes: item or uid, INV_ITEM_DELETED or INV_ITEM_MOVED
function bp:AddChange(it, what)
	local ch = self.Changes[it] or {}
	self.Changes[it] = ch
	ch[what] = true
end

function bp:Register(addstack)
	hook.Run("InventoryTypeRegistered", self, self.Name)
	Inventory.Networking.InventoryIDs[self.NetworkID] = self

	Inventory.RegisterClass(self.Name, self, Inventory.Inventories, (addstack or 0) + 1)
end

ChainAccessor(bp, "Items", "Items")
ChainAccessor(bp, "Slots", "Slots")
ChainAccessor(bp, "OwnerUID", "OwnerID")
ChainAccessor(bp, "OwnerUID", "OwnerUID")

if SERVER then
	include("inventory/inv_meta/backpack_sv_extension.lua")
	AddCSLuaFile("inventory/inv_meta/backpack_cl_extension.lua")
else
	include("inventory/inv_meta/backpack_cl_extension.lua")
end

bp:Register()