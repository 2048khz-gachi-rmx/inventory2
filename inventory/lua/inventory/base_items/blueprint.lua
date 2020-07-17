local gen = Inventory.GetClass("base_items", "generic_item")
local bp = gen:callable("Blueprint", "Blueprint")

bp:Register()
bp:NetworkVar("NetStack", function(it, write)
	local ns = netstack:new()
	if write then
		ns:WriteUInt(table.Count(self:GetRecipe()), 8)
		for k,v in pairs(self:GetRecipe()) do

		end
	else
		local amt = net.ReadUInt(8)
	end

	return ns
end)