local gen = Inventory.GetClass("base_items", "generic_item")
local bp = gen:ExtendItemClass("Blueprint", "Blueprint")

bp:NetworkVar("NetStack", function(it, write)

	if write then
		local ns = netstack:new()

		-- encode result
		ns:WriteString(it:GetResult())

		-- encode tier
		ns:WriteUInt(it:GetTier(), 4)

		-- encode recipe
		ns:WriteUInt(table.Count(it:GetRecipe()), 8)
		for k,v in pairs(it:GetRecipe()) do
			ns:WriteUInt(Inventory.Util.ItemNameToID(k), 16)
			ns:WriteUInt(v, 32)
		end

		-- encode modifiers
		ns:WriteUInt(table.Count(it:GetModifiers()), 8)

		for k,v in pairs(it:GetModifiers()) do
			ns:WriteUInt(Inventory.Modifiers.NameToID(k), 16)
			ns:WriteUInt(v, 16)
		end

		return ns
	else
		-- result
		local res = net.ReadString()
		it.Data.Result = res


		-- tier
		local tier = net.ReadUInt(4)
		it.Data.Tier = tier

		-- recipe
		local amt = net.ReadUInt(8)
		it.Data.Recipe = {}
		--printf("Recipe of %d components:", amt)
		for i=1, amt do
			local iid = net.ReadUInt(16)
			local name = Inventory.Util.ItemIDToName(iid)
			local needs = net.ReadUInt(32)
			--printf("	#%d: %s x%d", i, name, needs)
			it.Data.Recipe[name] = needs
		end

		-- modifiers
		local mods = net.ReadUInt(8)
		--printf("%d modifiers:", mods)
		it.Data.Modifiers = {}

		for i=1, mods do
			local id = net.ReadUInt(16)
			local name = Inventory.Modifiers.IDToName(id)
			local tier = net.ReadUInt(16)
			--printf("	#%d: %s %s", i, name, ("I"):rep(tier))
			it.Data.Modifiers[name] = tier
		end
	end

end, 'EncodeBlueprint')

bp:Register()