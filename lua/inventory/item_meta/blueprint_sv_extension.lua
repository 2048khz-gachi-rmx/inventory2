local bp = Inventory.ItemObjects.Blueprint

function bp:CreateResult(ply)
	local inv = ply.Inventory.Permanent
	if not inv then error("no inventory to stick result in") return end

	local it = Inventory.NewItem(self:GetResult(), self)
	local pr = inv:InsertItem(it)

	for k,v in pairs(self:GetModifiers()) do
		it:GetModifiers()[k] = v
	end

	return pr
end