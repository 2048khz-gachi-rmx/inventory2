
--[[
	Creates a brand new item and waits until you stick it into SQL with all the data necessary.
]]

local function makeItem(iid, invobj, dat)
	local itMeta = Inventory.Util.GetMeta(iid)
	if not itMeta then errorf("No item meta for IID %s", iid) return end

	local item = itMeta:new(nil, iid, false)
	local base = item:GetBaseItem()

	item.Data = table.Copy(base.DefaultData)

	if invobj then
		item:SetInventory(invobj)
	end

	if dat then
		for k,v in pairs(dat) do
			item.Data[k] = v
		end
	end

	return item
end

function Inventory.NewItem(iid, invobj, dat)
	assert(not invobj or IsInventory(invobj))

	local item = makeItem(iid, invobj, dat)
	item:InitializeNew()

	return item
end

--[[
	Creates an item using SQL info.
]]

function Inventory.ReconstructItem(uid, iid, invobj, dat)
	assert(not invobj or IsInventory(invobj))

	local itm = makeItem(iid, invobj, dat)
	itm:SetUID(uid)
	itm:Emit("AssignUID", uid)

	return itm
end

--[==================================[
	returns:
		1: table of NEW items (or false if item is unstackable)
		2: table of items that were stacked into
		3: amount of items left unstacked
--]==================================]

function Inventory.CheckStackability(inv, iid, dat)
	local base = Inventory.Util.GetBase(iid)
	if not base then
		return false, ("no base for iid %s"):format(iid)
	end

	if not dat or not dat.Amount then
		dat = {}
		if base:GetCountable() then
			dat.Amount = 1
		end
	end--return false end

	iid = Inventory.Util.ItemNameToID(iid)

	if not base or not base.Countable then return false, "base uncountable" end
	local maxstack = base:GetMaxStack()

	local amt = dat.Amount
	local stackedIn = {}

	for k,v in pairs(inv:GetItems()) do
		if v:GetItemID() ~= iid then continue end
		--if not equalData(dat, v:GetData()) then printf("not equal data (%s vs %s)", util.TableToJSON(dat), util.TableToJSON(v:GetData())) continue end --different-data'd items (except .Data.Amount) cannot be stacked

		local canStack = v:CanStack(dat, amt)
		if not canStack then continue end

		v:SetAmount(v:GetAmount() + math.min(amt, canStack))
		amt = amt - canStack
		if canStack > 0 then
			stackedIn[#stackedIn + 1] = v
		end

		if amt == 0 then return {}, stackedIn, 0 end -- stacked all in; return an empty table of new items
	end

	local canCreate = math.ceil(amt / maxstack)
	local newIts = {}

	for i=1, canCreate do
		local free = inv:GetFreeSlot()
		if not free then break end

		local canGive = math.min(maxstack, amt)

		local it = Inventory.NewItem(iid, inv, dat)
		it:SetAmount(canGive)
		it:SetSlot(free)

		newIts[i] = it

		amt = amt - canGive
	end

	return newIts, stackedIn, amt
end


function Inventory.TakeItems(inv, iid, amt, filter)
	filter = filter or BlankFunc
	iid = Inventory.Util.ItemNameToID(iid)
	if not iid then errorf("not an itemID or name: %s", iid) return end

	local invs = {inv}

	if not IsInventory(inv) and istable(inv) then
		invs = inv
	end

	local matches = {}
	local have_amt = 0

	for k, inv in ipairs(invs) do
		for k,v in pairs(inv:GetItems()) do
			if v:GetItemID() ~= iid then continue end
			if filter(iid) ~= false then
				matches[#matches + 1] = v
				have_amt = have_amt + v:GetAmount()
			end
		end
	end

	if have_amt < amt then return false end
	table.sort(matches, function(a, b)
		if a:GetAmount() ~= b:GetAmount() then
			return a:GetAmount() < b:GetAmount()
		end

		return a:GetSlot() > b:GetSlot()
	end)

	for k,v in ipairs(matches) do
		local take = math.min(amt, v:GetAmount())
		if take == v:GetAmount() then
			v:Delete()
		else
			v:SetAmount(v:GetAmount() - take)
		end

		amt = amt - take
	end

	return true
end