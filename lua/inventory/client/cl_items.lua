function Inventory.NewItem(iid, invobj, dat)
	local it = Inventory.Util.GetMeta(iid)
	if not it then errorf("No item meta for IID %s", iid) return end

	local item = it:new(nil, iid, false)
	if invobj then
		item:SetInventory(invobj)
	end

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

function Inventory.ReconstructItem(uid, iid, invobj, data)
	local itm = Inventory.NewItem(iid, invobj, data)
	itm:SetNWID(uid)

	return itm
end