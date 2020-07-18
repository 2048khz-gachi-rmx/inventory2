local gen = Inventory.GetClass("base_items", "generic_item")
local bp = Inventory.BaseItemObjects.Blueprint or gen:callable("Blueprint", "Blueprint")



bp:NetworkVar("NetStack", function(it, write)
	local ns = netstack:new()
	print("networkvar called")

	if write then
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

		for i=1, amt do
			local iid = net.ReadUInt(16)
			local name = Inventory.Util.ItemIDToName(iid)
			local amt = net.ReadUInt(32)
			print(iid, name)
			it.Data.Recipe[name] = amt
		end

		-- modifiers
		local mods = net.ReadUInt(8)
		it.Data.Modifiers = {}

		for i=1, amt do
			local id = net.ReadUInt(16)
			local name = Inventory.Modifiers.IDToName(id)
			local tier = net.ReadUInt(16)

			it.Data.Modifiers[name] = tier
		end
	end

	return ns
end, 'EncodeBlueprint')

bp:Register()