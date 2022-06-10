local gen = Inventory.GetClass("base_items", "generic_item")
local typed = gen:ExtendItemClass("Typed", "Typed")
typed.Types = {}

typed:NetworkVar("NetStack", function(it, write)
	if write then
		local ns = netstack:new()
		local id = it:GetTypeID()

		if id then
			ns:WriteBool(true)
			ns:WriteUInt(id, 15)
		else
			ns:WriteBool(false)
		end

		return ns
	else
		local b = net.ReadBool()

		if b then
			local id = net.ReadUInt(15)
			it:SetTypeID(id)
		end
	end

end, "Type")

typed:Register()