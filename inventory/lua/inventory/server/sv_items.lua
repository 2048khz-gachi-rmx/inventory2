
--[[
	Creates a brand new item and waits until you stick it into SQL with all the stats necessary.
	Don't use this for creating items pulled from SQL!
]]

function Inventory.NewItem(iid, invobj, dat)
	local it = Inventory.Util.GetMeta(iid)

	local item = it:new(nil, iid)
	item.Inventory = invobj

	local base = item:GetBaseItem()

	local def = table.Copy(base.DefaultData)

	if dat then
		for k,v in pairs(dat) do
			def[k] = v
		end
	end

	item.Data = def

	return item
end

local function equalData(dat1, dat2)
	for k,v in pairs(dat1) do
		if dat2[k] ~= v and k ~= "Amount" then
			return false
		end
	end
	return true
end

function Inventory.CheckStackability(inv, iid, cb, slot, dat)
	if not dat or not dat.Amount then return false end

	iid = Inventory.Util.ItemNameToID(iid)
	local base = Inventory.Util.GetBase(iid)

	if not base or not base.Countable then return false end
	local maxstack = base:GetMaxStack()

	local amt = dat.Amount

	for k,v in pairs(inv:GetItems()) do
		if v:GetItemID() ~= iid then printf("not same itemids (%s vs %s)", v:GetItemID(), iid) continue end
		if not equalData(dat, v:GetData()) then printf("not equal data (%s vs %s)", util.TableToJSON(dat), util.TableToJSON(v:GetData())) continue end --different-data'd items (except .Data.Amount) cannot be stacked

		local max = v:GetMaxStack()
		local cur = v:GetAmount()

		local canStack = math.min(max - cur, amt)
		v:SetAmount(cur + canStack)
		amt = amt - canStack
		if amt == 0 then return end
		if amt < 0 then errorf("How the fuck did amount become less than 0: canStack %d, max %d, amt %d", canStack, max, amt) return end
	end

	local canCreate = math.ceil(amt / maxstack)
	local ret = {}
	printf("creating %d items for %d amt", canCreate, amt)

	for i=1, canCreate do
		local free = inv:GetFreeSlot()
		if not free then break end

		local canGive = math.min(maxstack, amt)
		local it = Inventory.NewItem(iid, inv, {Amount = canGive})
		it:SetSlot(free)

		ret[i] = it

		amt = amt - canGive
	end

	return ret, amt
end