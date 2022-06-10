--

-- does not modify any input data
-- returns:
-- 	1: false if all items fit, number of items unstacked otherwise
-- 	2: table - { {existing_item, to_stack}, {...} }; can be false if item unstackable
--  3: table - { [slot_create_in] = amt, ... }; same

local sortFn = function(a, b)
	return a[1]:GetSlot() < b[1]:GetSlot()
end

local none = {
	-- Slots = {allowed_stack_slot, ...}, -- slots we're allowed to stack to
	-- NYI: NewSlots = {allowed_new_slot, ...} -- slots we're allowed to create new items in
	-- AllowNew = true/false -- whether we should attempt to create new items
}

function Inventory.GetInventoryStackInfo(inv, item, opts)
	opts = istable(opts) and opts or none

	CheckArg(1, inv, IsInventory, "Inventory")
	CheckArg(2, item, IsItem, "Item")

	local candidates = {}
	local stackAmt = item:GetAmount()
	local maxStack = item:GetBase():GetMaxStack()

	if not maxStack then
		return false, false, false
	end

	local candAmt = stackAmt
	-- new items are slotted instantly while uid assignment might take a while

	if istable(opts.Slots) then
		for _, slot in pairs(opts.Slots) do
			local invItm = inv:GetItemInSlot(slot)
			if not invItm then continue end

			local amt = invItm:CanStack(item, candAmt)
			if amt then
				candidates[#candidates + 1] = {invItm, amt}
				assert(amt >= 0)
				candAmt = candAmt - amt
			end
		end
	else
		for slot, itm in pairs(inv:GetSlots()) do
			--if stackAmt <= 0 then break end
			local amt = itm:CanStack(item, candAmt)

			if amt then
				candidates[#candidates + 1] = {itm, amt}
				assert(amt >= 0)
				candAmt = candAmt - amt
			end
		end
	end

	assert(stackAmt >= 0)
	assert(candAmt >= 0)

	table.sort(candidates, sortFn)

	for k, dat in ipairs(candidates) do
		if stackAmt <= 0 then
			print("nilled", k)
			candidates[k] = nil
		end

		stackAmt = stackAmt - dat[2]
	end

	local createNew = {}

	if stackAmt > 0 and opts.AllowNew == false then
		return stackAmt, candidates, createNew
	end

	local ignoreSlots = {}
	local optSlots = opts.Slots
	local cpyIdx = 1

	while stackAmt > 0 do
		local slot

		if optSlots then
			slot = optSlots[cpyIdx]
			if not slot then
				return stackAmt, candidates, createNew
			end

			cpyIdx = cpyIdx + 1

			if not inv:IsSlotLegal(slot) or inv:GetItemInSlot(slot) then
				continue
			end
		else
			slot = inv:GetFreeSlot(ignoreSlots)

			if not slot then
				return stackAmt, candidates, createNew
			end
		end

		local toCreate = math.min(maxStack, stackAmt)

		stackAmt = stackAmt - toCreate

		ignoreSlots[slot] = true
		createNew[slot] = toCreate
	end

	return false, candidates, createNew
end

function Inventory.CreateStackedItems(inv, from, tbl)
	local iid = from:GetItemID()

	local ret = {}

	local dat = from:GetData()

	for slot, amt in pairs(tbl) do
		dat.Amount = amt -- for initializers i guess?

		local it = Inventory.NewItem(iid, inv, dat)
		it:SetAmount(amt)
		it:SetSlot(slot)

		ret[#ret + 1] = it
	end

	return ret
end