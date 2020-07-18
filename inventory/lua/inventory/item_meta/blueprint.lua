--sasa

local gen = Inventory.GetClass("item_meta", "generic_item")
local bp = Inventory.ItemObjects.Blueprint or gen:Extend("Blueprint")

bp.IsBlueprint = true


function bp:Initialize(uid, iid)


end

function bp:GetName()
	local wep = weapons.Get(self:GetResult()).PrintName
	return ("T%d %s Blueprint"):format(self:GetTier(), wep)
end
DataAccessor(bp, "Result", "Result")
DataAccessor(bp, "Modifiers", "Modifiers")
DataAccessor(bp, "Stats", "Stats")
DataAccessor(bp, "Recipe", "Recipe")
DataAccessor(bp, "Tier", "Tier")

bp:Register()


bp:On("GenerateText", "BlueprintModifiers", function(self, cloud, markup)
	cloud.MaxW = 250

	for k,v in pairs(self:GetModifiers()) do
		local mod = markup:AddPiece()
		mod:AddText(k)
	end

end)