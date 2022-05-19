local bp = Inventory.Inventories.Backpack

function bp:CanCrossInventoryMove(it, inv2, slot)
	if it:GetInventory() ~= self then
		errorf("Can't move an item from an inventory which it doesn't belong to! (item) %q vs %q (self)", it:GetInventory(), self)
		return false
	end

	if self == inv2 then
		errorf("Can't cross-inv between the same inventory! %s vs. %s", self, inv2)
		return false
	end

	if _FORCE_ALLOW_INV_ACTIONS then return true, "debug allowed" end

	slot = slot or inv2:GetFreeSlot()
	if slot and inv2:IsSlotLegal(slot) == false then return false, "illegal slot " .. tostring(slot) end

	local can, why = inv2:HasAccess(CachedLocalPlayer(), "CrossInventoryTo", it, self)
	if not can then return false, "no access to other inv: " .. why end

	can, why = self:HasAccess(CachedLocalPlayer(), "CrossInventoryFrom", it, inv2)
	if not can then return false, "no access to self: " .. why end

	--check if inv2 can accept cross-inventory item
	can = inv2:Emit("CanMoveTo", it, self)
	if can == false then return false end

	--check if inv1 can give out the item
	can = self:Emit("CanMoveFrom", it, inv2)
	if can == false then return false end

	--check if inv2 can add an item to itself
	can = inv2:Emit("CanAddItem", it, it:GetUID())
	if can == false then return false end

	return true
end

function bp:CanCrossInventoryMoveSwap(it, inv2, slot)
	slot = slot or inv2:GetFreeSlot()
	if not slot then
		return false, "no slot " .. tostring(slot)
	end

	if not inv2:IsSlotLegal(slot) then
		printf("Attempted to move item out of inventory bounds (%s > %s)", slot, inv2.MaxItems)
		return false, "illegal slot " .. slot
	end

	local other_item = inv2:GetItemInSlot(slot)

	if other_item then
		local can, why = inv2:CanCrossInventoryMove(other_item, self, it:GetSlot())
		print("other item allowed move to", self, can, why)
		if not can then self:vprint(inv2, "#1 doesn't allow CIM", why) return false, why end
	end

	local can, why = self:CanCrossInventoryMove(it, inv2, nil)
	if not can then self:vprint(self, "#2 doesn't allow CIM", why) return false, why end

	return true
end

local function ActuallyMove(inv1, inv2, it, slot)
	inv1:RemoveItem(it)
	it:SetSlot(slot)

	inv2:AddItem(it, true)
end

-- from:CrossInventoryMove(itm, to)

function bp:CrossInventoryMove(it, inv2, slot)
	local other_item = inv2:GetItemInSlot(slot)

	local ok, why = self:CanCrossInventoryMoveSwap(it, inv2, slot)
	if not ok then return false, why end

	if other_item then
		ActuallyMove(inv2, self, other_item, it:GetSlot())
	end

	ActuallyMove(self, inv2, it, slot)

	self:Emit("CrossInventoryMovedFrom", it, inv2, slot)
	inv2:Emit("CrossInventoryMovedTo", it, self, slot)

	it:MoveToInventory(inv2, slot)
	return true
end

function bp:PickupInfo(it, ignore_emitter)
	CheckArg(1, it, IsItem, "Item")

	local prs = {}

	--[[if not it:GetSlot() then
		it:SetSlot(self:GetFreeSlot())
	end]]

	local can, why, fmts = self:_CanAddItem(it, ignore_emitter, true)

	if not can then
		if why then
			errorf(why, unpack(fmts or {}))
		end

		return false
	end

	local left, itStk, newStk = Inventory.GetInventoryStackInfo(self, it)

	if not left and not itStk then
		local slot = self:GetFreeSlot()
		if not slot then
			return false, false
		end

		if it:GetInventory() then
			it:GetInventory():RemoveItem(it)
		end

		it:SetSlot(slot)
		self:AddItem(it, ignore_emitter)

		return false, {}, {it} -- no left/ no stacked/ new item
	end

	for _, dat in ipairs(itStk) do
		local v, amt = unpack(dat)
		v:Stack(it)
	end

	local newIts = Inventory.CreateStackedItems(self, it, newStk)

	for k,v in ipairs(newIts) do
		prs[#prs + 1] = self:AddItem(v, ignore_emitter)
	end

	if not self.ReadingNetwork then
		self:Emit("Change")
	end

	if left then
		it:SetAmount(left)
	else
		it:Delete()
	end

	return left, itStk, newIts
end

function bp:RequestPickup(it, thenDo)
	local ns = Inventory.Networking.Netstack()
		ns:WriteInventory(it:GetInventory())
		ns:WriteItem(it, true)
		ns:WriteInventory(self)
	Inventory.Networking.PerformAction(INV_ACTION_PICKUP, ns)

	if thenDo then -- lole
		self:PickupInfo(it)
	end
end

function bp:RequestCrossInventoryMove(it, inv2, slot)
	if not self:CrossInventoryMove(it, inv2, slot) then return false end

	local ns = Inventory.Networking.Netstack()
		ns:WriteInventory(self)
		ns:WriteItem(it, true)

		ns:WriteInventory(inv2)
		ns:WriteUInt(slot, 16)
	Inventory.Networking.PerformAction(INV_ACTION_CROSSINV_MOVE, ns)

	return true
end

function bp:CanMove(it, slot)
	local can = self:Emit("CanMoveItem", it, slot)
	if can == false then return false end

	return true
end

function bp:RequestMove(it, slot)
	if not self:CanMove(it, slot) then return false end

	it:MoveToSlot(slot)

	local ns = Inventory.Networking.Netstack()
		ns:WriteInventory(self)
		ns:WriteItem(it)
		ns:WriteUInt(slot, 16)
	Inventory.Networking.PerformAction(INV_ACTION_MOVE, ns)
	return true
end

function bp:CanStack(out, _in, amt)
	local amt = _in:CanStack(out, amt)
	if not amt then return false end

	return amt
end

function bp:RequestStack(item_out, item_in, amt)

	amt = self:CanStack(item_out, item_in, amt)
	if not amt then return false end

	local crossinv = item_out:GetInventory() ~= item_in:GetInventory()
	local act_enum = crossinv and INV_ACTION_CROSSINV_MERGE or INV_ACTION_MERGE

	local ns = Inventory.Networking.Netstack()

		if crossinv then
			local a, b = item_out:GetInventory()
			ns:WriteInventory(a, b)
			ns:WriteItem(item_out)
		end

		ns:WriteInventory(item_in:GetInventory())
		if not crossinv then
			ns:WriteItem(item_out)
		end
		ns:WriteItem(item_in)
		ns:WriteUInt(amt, 32)

	item_in:SetAmount(item_in:GetAmount() + amt)
	item_out:SetAmount(item_out:GetAmount() - amt)

	Inventory.Networking.PerformAction(act_enum, ns)

	return true
end