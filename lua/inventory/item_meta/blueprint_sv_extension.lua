local bp = Inventory.ItemObjects.Blueprint

function bp:CreateResult(ply)
	local inv = ply.Inventory.Permanent
	if not inv then error("no inventory to stick result in") return end

	local it = Inventory.NewItem(self:GetResult(), inv)

	it:SetQualityName(self:GetQualityName())
	it:SetModNames(self:GetModNames())
	it:SetStatRolls(self:GetStatRolls())

	local pr = inv:InsertItem(it)

	return pr
end