local bp = Inventory.BaseItemObjects.Blueprint

bp:NetworkVar("NetStack", function(it, write)
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
		local needs = net.ReadUInt(16)

		it.Data.Recipe[name] = needs
	end
end, "EncodeBlueprint")