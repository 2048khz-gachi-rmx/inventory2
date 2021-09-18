local uq = Inventory.BaseItemObjects.Unique

uq:NetworkVar("NetStack", function(it)
	-- modifiers
	local mods = net.ReadUInt(8)
	it.Data.Modifiers = {}

	for i=1, mods do
		local id = net.ReadUInt(8)
		local name = Inventory.Modifiers.IDToName(id)
		local tier = net.ReadUInt(8)

		it.Data.Modifiers[name] = tier
	end

	-- stats
	local stats = net.ReadUInt(8)

	it.Data.Stats = {}

	for i=1, stats do
		local name, fr = Inventory.Stats.Read()
		it.Data.Stats[name] = fr
	end
end, "ModsStats")