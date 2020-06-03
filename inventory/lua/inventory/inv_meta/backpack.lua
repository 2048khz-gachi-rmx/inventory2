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

function bp:DeleteItem(it)
	local uid = (isnumber(it) and it) or it:GetUID()

	local it = self:GetItems()[uid]
	self:GetItems()[uid] = nil

	if it:GetKnown() then self:AddChange(it, INV_ITEM_DELETED) else self:AddChange(it, nil) end --if the player doesn't know about the item, don't even tell him about the deletion
	return it
end

function bp:MoveItem(it, slot)	--this is a utility function which swaps slots if an item exists and stores the slot change in sql
	if self.MaxItems and slot > self.MaxItems then errorf("Attempted to move item out of inventory bounds (%d > %d)", slot, self.MaxItems) return end
	local it2 = self:GetItemInSlot(slot)
	local b4slot = it:GetSlot()

	if it == it2 or it:GetSlot() == slot then return false end

	it:SetSlot(slot)
	if it2 then it2:SetSlot(b4slot) end

	if SERVER then Inventory.MySQL.SwitchSlots(it, it2) end
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

function bp:NewItem(iid, cb, slot)

	slot = slot or self:GetFreeSlot()
	if not slot or slot > self.MaxItems then errorf("Didn't find a slot where to put the item or it was above MaxItems! (%s > %d)", slot, self.MaxItems) return end

	local it = Inventory.NewItem(iid, self, cb)
	it:SetSlot(slot)
	it:Insert(self)

	if it:GetUID() then
		self:AddItem(it)
		cb(it, slot)
	else
		it:On("AssignUID", function() self:AddItem(it) cb(it, slot) end)
	end
end


--[[------------------------------]]
--	    Networking & shtuff
--[[------------------------------]]

function bp:SerializeItems(typ)
	local max_uid = 0
	local max_id = 0
	local amt = 0

	if typ == INV_NETWORK_FULLUPDATE or typ == nil then
		for k,v in pairs(self:GetItems()) do
			max_uid = math.max(max_uid, v:GetUID())
			max_id = math.max(max_id, v:GetIID())
			amt = amt + 1
		end

	elseif typ == INV_NETWORK_UPDATE then

		for k,v in pairs(self:GetItems()) do
			if self.Changes[v] ~= INV_ITEM_ADDED then continue end
			max_uid = math.max(max_uid, v:GetUID())
			max_id = math.max(max_id, v:GetIID())
			amt = amt + 1
		end

	end

	print("writing", amt, "items")
	local ns = Inventory.Networking.NetStack(max_uid, max_id)

	ns:WriteUInt(self.NetworkID, 16).InventoryNID = true
	ns:WriteUInt(amt, 16).ItemsAmount = true


	if typ == INV_NETWORK_FULLUPDATE or typ == nil then
		for k,v in pairs(self:GetItems()) do
			v:Serialize(ns)
			v:SetKnown(true)
		end

	elseif typ == INV_NETWORK_UPDATE then
		for k,v in pairs(self:GetItems()) do
			if self.Changes[v] ~= INV_ITEM_ADDED then continue end
			v:Serialize(ns)
			v:SetKnown(true)

			self.Changes[v] = nil
		end

	end


	return ns
end

--takes: item or uid, INV_ITEM_DELETED or INV_ITEM_MOVED
function bp:AddChange(it, what)
	self.Changes[it] = what
end

function bp:WriteChanges(ns)
	local dels, moves, allits = {}, {}, {}

	local where = {
		[INV_ITEM_DELETED] = dels,
		[INV_ITEM_MOVED] = moves,
	}

	for item, enum in pairs(self.Changes) do
		if not where[enum] then printf("Unknown change enum in %s! Ignoring... (%s: %q)", self.Name, item, enum) continue end
		where[enum][#where[enum] + 1] = item
		allits[#allits + 1] = item
	end

	ns:Resize(allits)

	ns:WriteUInt(#dels, 16).DeletionAmt = true
	for k,v in ipairs(dels) do
		ns:WriteUID(v)
	end

	ns:WriteUInt(#moves, 16).MovedAmt = true

	for k,v in ipairs(moves) do
		ns:WriteUID(v)
		ns:WriteSlot(v)
	end
end

function bp:Register()
	hook.Run("InventoryTypeRegistered", self, self.Name)
	Inventory.Networking.InventoryIDs[self.NetworkID] = self
end

ChainAccessor(bp, "Items", "Items")
ChainAccessor(bp, "OwnerUID", "OwnerID")
ChainAccessor(bp, "OwnerUID", "OwnerUID")

if not Inventory.BackpackRegistered then
	hook.Add("OnInventoryLoad", "RegisterBackpack", function()
		bp:Register()
		Inventory.BackpackRegistered = true
	end)
	Inventory.BackpackRegistered = true
else
	bp:Register()
end
