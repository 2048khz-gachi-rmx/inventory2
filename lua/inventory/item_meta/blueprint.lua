--sasa

local gen = Inventory.GetClass("item_meta", "generic_item")
local bp = Inventory.ItemObjects.Blueprint or gen:Extend("Blueprint")

bp.IsBlueprint = true

function bp:Initialize(uid, iid)

end

function bp:GetResultName()
	local wep = weapons.GetStored(self:GetResult())
	if not wep then return "Invalid weapon" end

	return wep.PrintName
end

function bp:GetName()
	local wep = weapons.GetStored(self:GetResult())
	if not wep then
		return ("T%d %s [%s] Blueprint"):format(self:GetTier(), "Invalid weapon", self:GetResult())
	end

	return ("T%d %s Blueprint"):format(self:GetTier(), wep.PrintName)
end
DataAccessor(bp, "Result", "Result")
DataAccessor(bp, "Modifiers", "Modifiers")
DataAccessor(bp, "Stats", "Stats")
DataAccessor(bp, "Recipe", "Recipe")
DataAccessor(bp, "Tier", "Tier")

bp:Register()




function bp:GetWeaponType()
	return Inventory.Blueprints.WeaponPoolReverse[self:GetResult()]
end

include("blueprint_" .. Rlm(true) .. "_extension.lua")