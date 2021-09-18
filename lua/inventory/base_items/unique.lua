local gen = Inventory.GetClass("base_items", "generic_item")
local uq = gen:ExtendItemClass("Unique", "Unique")

uq:NetworkVar("NetStack", function(it, write)
	if write then
		local ns = netstack:new()
		ns:WriteUInt(it:GetQuality():GetID(), 16)
		return ns
	else
		local q = net.ReadUInt(16)
		local ql = Inventory.Qualities.Get(q)

		it:SetQuality(ql)
	end

end, "Quality")

uq:Register()

include("unique_" .. Rlm(true) .. "_ext.lua")