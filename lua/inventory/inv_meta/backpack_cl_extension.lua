
local bp = Inventory.Inventories.Backpack

function bp:CanCrossInventoryMove(it, inv2, slot)
	if it:GetInventory() ~= self then
		errorf("Can't move an item from an inventory which it doesn't belong to! (item) %q vs %q (self)", it:GetInventory(), self)
		return false
	end

	if not inv2:HasAccess(LocalPlayer(), "CrossInventoryTo") then return false end
	if not self:HasAccess(LocalPlayer(), "CrossInventoryFrom") then return false end

	if self == inv2 then
		errorf("Can't cross-inv between the same inventory! %s vs. %s", self, inv2)
		return false
	end

	slot = slot or inv2:GetFreeSlot()
	if not slot then
		return false
	end

	if not inv2:IsSlotLegal(slot) then
		return false
	end

	-- todo: is this necessary?

	--check if inv2 can accept cross-inventory item
	local can = inv2:Emit("CanCrossMoveTo", it, self)
	if can == false then return false end

	--check if inv1 can give out the item
	can = self:Emit("CanCrossMoveFrom", it, inv2)
	if can == false then return false end

	--check if inv2 can add an item to itself
	can = inv2:Emit("CanAddItem", it, it:GetUID())
	if can == false then return false end

	return true
end

local function ActuallyMove(inv1, inv2, it, slot)
	inv1:RemoveItem(it)
	it:SetSlot(slot)

	inv2:AddItem(it, true)
end

function bp:CrossInventoryMove(it, inv2, slot)
	local other_item = inv2:GetItemInSlot(slot)

	if other_item and not inv2:CanCrossInventoryMove(other_item, self, it:GetSlot()) then
		return false
	end

	if not self:CanCrossInventoryMove(it, inv2, slot) then return false end

	if other_item then
		--print("other item:", other_item)
		ActuallyMove(inv2, self, other_item, it:GetSlot())
	end

	--print("this item:", it, inv2, slot)
	ActuallyMove(self, inv2, it, slot)

	self:Emit("CrossInventoryMovedFrom", it, inv2, slot)
	inv2:Emit("CrossInventoryMovedTo", it, self, slot)

	return true
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

	local ns = Inventory.Networking.Netstack()

	ns:WriteInventory(self)
	ns:WriteItem(it)

	ns:WriteUInt(slot, 16)

	it:SetSlot(slot) --assume success

	Inventory.Networking.PerformAction(crossinv and INV_ACTION_CROSSINV_MOVE or INV_ACTION_MOVE, ns)
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

	local ns = Inventory.Networking.Netstack()

	local crossinv = item_out:GetInventory() ~= item_in:GetInventory()
	local act_enum = crossinv and INV_ACTION_CROSSINV_MERGE or INV_ACTION_MERGE

	if crossinv then
		ns:WriteInventory(item_out:GetInventory())
		ns:WriteItem(item_out)
	end

	ns:WriteInventory(item_in:GetInventory())
	if not crossinv then
		ns:WriteItem(item_out)
	end
	ns:WriteItem(item_in)
	ns:WriteUInt(amt, 32)

	

	Inventory.Networking.PerformAction(act_enum, ns)

	item_in:SetAmount(item_in:GetAmount() + amt)
	item_out:SetAmount(item_out:GetAmount() - amt)
	return true
end