local uq = Inventory.BaseItemObjects.Unique

uq:NetworkVar("NetStack", function(it)
	local ns = netstack:new()

	-- encode modifiers
	ns:WriteUInt(table.Count(it:GetModifiers()), 8)

	for k,v in pairs(it:GetModifiers()) do
		ns:WriteUInt(Inventory.Modifiers.NameToID(k), 8)
		ns:WriteUInt(v, 8)
	end

	-- encode stats
	if it:GetStatRolls() then
		ns:WriteUInt(table.Count(it:GetStatRolls()), 8)

		for k,v in pairs(it:GetStatRolls()) do
			Inventory.Stats.Write(k, v, ns)
		end
	else
		ns:WriteUInt(0, 8)
	end

	return ns
end, "ModsStats")