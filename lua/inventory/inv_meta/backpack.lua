local bp = Inventory.Inventories.Backpack or Emitter:extend()
Inventory.Inventories.Backpack = bp

bp.IsInventory = true
bp.IsPlayerInventory = true

bp.Name = "Backpack"
bp.SQLName = "ply_temp"
bp.NetworkID = 1
bp.MaxItems = 20
bp.UseSlots = true

bp.UseSQL = true

bp.IsBackpack = true
bp.AutoFetchItems = true
bp.SupportsSplit = true


bp.Icon = {
	URL = "https://i.imgur.com/KBYX2uQ.png",
	Name = "bag.png"
}

function bp:__tostring()
	return ("%s [%p](owner: %s)"):format(
		self.Name, self,
		( IsValid(self.Owner) and tostring(self.Owner) .. ("[UID: %s] "):format(self.OwnerUID) )
			or self.OwnerUID
	)
end

function bp:OnExtend(new_inv)
	new_inv.SQLName = false 	--set these yourself!!
	new_inv.NetworkID = false
	new_inv.Name = "unnamed inventory!?"
	new_inv.IsBackpack = false

	new_inv.Icon = false
end

function bp:Initialize(ply)
	self.Items = {}
	self.Slots = {}
	self.Changes = {}

	if ply then
		self:SetOwner(ply)

		if SERVER and self.AutoFetchItems then
			self.FetchPr = Inventory.MySQL.FetchPlayerItems(self, ply)
			self.FetchPr:Then(function()
				self.FetchPr = nil
			end)
		end
	end
end

function bp:SetOwner(ply)
	self.Owner = ply
	if ply:IsPlayer() then self:SetOwnerUID(ply:SteamID64()) end
	self:Emit("OwnerAssigned", ply)
end

function bp:GetOwner()
	return self.Owner, self.OwnerUID
end

function bp:IsOwner(w)
	return w == self.Owner or w == self.OwnerUID
end

function bp:_SetSlot(it, slot)
	local emit = self:Emit("SetSlot", it, slot)
	if emit ~= nil then
		slot = emit
	end

	for i=1, self.MaxItems do
		if self.Slots[i] == it then
			self.Slots[i] = nil
			--not breaking. just in case there's more.
		end
	end

	self.Slots[slot] = it
	if it:GetUID() then
		self.Items[it:GetUID()] = it
	end

	if it:GetKnown() then self:AddChange(it, INV_ITEM_MOVED) end --if the player doesn't know about the item, don't replace the change
	return slot
end


function bp:RemoveItem(it, noChange, suppresserror)
	--just removes an item from itself and networks the change

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

	if slot and slots[slot] == foundit then
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
	its[foundit:GetUID()] = nil

	--if the player doesn't know about the item, don't even tell him about the deletion
	if foundit:GetKnown() and not noChange then
		self:AddChange(foundit, INV_ITEM_DELETED)
	else
		self.Changes[foundit] = nil
	end

	if not self.ReadingNetwork then
		self:Emit("Change")
	end

	self:Emit("RemovedItem", it, slot)
	return foundit
end

function bp:DeleteItem(it, suppresserror)
	--actually completely deletes an item, both from the backpack and from MySQL completely
	local uid = (isnumber(it) and it) or it:GetUID()

	local it = self:RemoveItem(it, nil, suppresserror)

	if SERVER then Inventory.MySQL.DeleteItem(it) end
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

	it:SetSlot(slot, false)
	if it2 then it2:SetSlot(b4slot, false) end

	if SERVER then return Inventory.MySQL.SwitchSlots(it, it2) end
end

function bp:GetItemInSlot(slot)
	return self.Slots[slot]
end

function bp:_CanAddItem(it, ignore_emitter, ignore_slot, ignore_inv)
	if not it:GetSlot() and not ignore_slot then
		return false, "Can't add an item without a slot set! Set a slot first!\nItem: %s", {it}
	end

	if not ignore_inv and it:GetInventory() and it:GetInventory() ~= self then
		return false, "Can't add an item that already has an inventory," ..
			"remove it from the old inventory first!\n" ..
			"Item: %s\n" ..
			"Item's inv: %s\n" ..
			"Attempted inv: %s\n----\n", {it, it:GetInventory(), self}
	end

	if not ignore_emitter then
		local can = self:Emit("CanAddItem", it, it:GetUID())
		if can == false then return false end
	end

	if self.Slots[it:GetSlot()] == it then
		return it:GetSlot()
	--[[
	-- bad idea: some mechanics (ie equip) use this to override an item in a slot easily
	-- this should be fine
	elseif self.Slots[it:GetSlot()] then
		return false --, "Already had an item in slot %s (%s)", {it:GetSlot(), self.Slots[it:GetSlot()]}
		]]
	end

	return true
end

function bp:AddItem(it, ignore_emitter, nochange)
	local can, why, fmts = self:_CanAddItem(it, ignore_emitter)

	if not can then
		if why then
			errorf(why, unpack(fmts or {}))
		end

		return
	end

	it:SetInventory(self)

	if it:GetUID() then
		self.Items[it:GetUID()] = it
	else
		it:On("AssignUID", "WriteWithUID", function()
			if it:GetInventory() == self then
				self.Items[it:GetUID()] = it
			end
		end)
	end

	self.Slots[it:GetSlot()] = it

	if not nochange then
		self:AddChange(it, INV_ITEM_ADDED)
	end

	self:Emit("AddItem", it, it:GetUID())

	if not self.ReadingNetwork then
		self:Emit("Change")
	end

	return it:GetSlot()
end

function bp:GetFreeSlot(ignore_slots)
	local slots = self.Slots

	for i=1, self.MaxItems do
		if not slots[i] and (not ignore_slots or not ignore_slots[i]) then
			return i
		end
	end

end

function bp:GetItem(uid)
	return self:GetItems()[uid]
end

function bp:HasItem(it)
	if IsItem(it) then
		return self:GetItem(it:GetUID()) == it
	else
		return self:GetItem(it)
	end
end

function bp:Reset()
	table.Empty(self.Items)
	table.Empty(self.Slots)
end

function bp:HasAccess(ply, action, ...)
	if self.DisallowAllActions then return false end

	local allow = self:Emit("Can" .. action, ply, ...)
	if allow ~= nil then return allow end

	if self["ActionCan" .. action] ~= nil then
		local allow

		if isfunction(self["ActionCan" .. action]) then
			allow = self["ActionCan" .. action] (self, ply, ...)
		else
			allow = self["ActionCan" .. action]
		end
		return allow
	end

	return ply == self:GetOwner()
end

function bp:RemoveChange(it, what)
	if not self.Changes[it] then return end
	self.Changes[it][what] = nil
end

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

function bp:GetSlotBits()
	return bit.GetLen(self.MaxItems)
end

function bp:ValidateSlot(sl)
	return sl > 0 and sl <= self.MaxItems and sl
end

ChainAccessor(bp, "Name", "Name")
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