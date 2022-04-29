local bp = Inventory.BaseItemObjects.Blueprint

bp:NetworkVar("NetStack", function(it, write)
	local ns = netstack:new()

	-- encode result
	ns:WriteString(it:GetResult())

	-- encode tier
	ns:WriteUInt(it:GetTier(), 4)

	-- encode recipe
	ns:WriteUInt(table.Count(it:GetRecipe() or {}), 8)
	for k,v in pairs(it:GetRecipe() or {}) do
		ns:WriteUInt(Inventory.Util.ItemNameToID(k), 16)
		ns:WriteUInt(v, 16)
	end

	return ns
end, "EncodeBlueprint")