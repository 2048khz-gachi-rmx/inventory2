--

-- does not modify any input data
-- returns:
-- 	1: bool - all of the items fit?
-- 	2: table - { {existing_item, to_stack}, {...} }
--  3: table - { [slot_create_in] = amt, ... }

function Inventory.GetInventoryStackInfo(inv, item)
	CheckArg(1, inv, IsInventory, "Inventory")
	CheckArg(2, item, IsItem, "Item")

	local candidates = {}
	local stackAmt = item:GetAmount()
	local maxStack = item:GetBase():GetMaxStack()

	if not maxStack then
		return false, false, false
	end

	-- new items are slotted instantly while uid assignment might take a while
	for slot, itm in pairs(inv:GetSlots()) do
		--if stackAmt <= 0 then break end

		local amt = itm:CanStack(item, stackAmt)
		if amt then
			candidates[#candidates + 1] = {itm, amt}
			--stackAmt = stackAmt - amt
		end
	end

	assert(stackAmt >= 0)

	table.sort(candidates, function(a, b)
		return a[1]:GetSlot() < b[1]:GetSlot()
	end)

	for k, dat in ipairs(candidates) do
		if stackAmt <= 0 then
			candidates[k] = nil
		end

		stackAmt = stackAmt - dat[2]
	end

	local createNew = {}
	local ignoreSlots = {}

	while stackAmt > 0 do
		local slot = inv:GetFreeSlot(ignoreSlots)
		if not slot then
			return stackAmt, candidates, createNew
		end

		local toCreate = math.min(maxStack, stackAmt)
		print("adding createNew in slot", slot, toCreate, stackAmt)
		stackAmt = stackAmt - toCreate

		ignoreSlots[slot] = true
		createNew[slot] = toCreate
	end

	return false, candidates, createNew
end

function Inventory.CreateStackedItems(inv, tpl, tbl)
	local base = Inventory.Util.GetBase(tpl)
	local iid = tpl:GetItemID()

	local ret = {}

	for slot, amt in pairs(tbl) do
		local it = Inventory.NewItem(iid, inv, dat)
		it:SetAmount(amt)
		it:SetSlot(slot)

		ret[#ret + 1] = it
	end

	return ret
end