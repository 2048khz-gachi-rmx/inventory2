--sasa

local gen = Inventory.GetClass("item_meta", "unique_item")
local bp = Inventory.ItemObjects.Blueprint or gen:Extend("Blueprint")

bp.IsBlueprint = true

DataAccessor(bp, "Result", "Result")
DataAccessor(bp, "Recipe", "Recipe")
DataAccessor(bp, "Tier", "Tier")

function bp:Initialize(uid, iid)

end

function bp:GetResultName()
	local wep = weapons.GetStored(self:GetResult())
	if not wep then return "Invalid weapon" end

	return wep.PrintName
end

function bp:GetName()
	local wep = weapons.GetStored(self:GetResult())
	local qName = self:GetQuality() and self:GetQuality():GetName() or "Mundane"
	if not wep then
		return ("T%d %s [%s] Blueprint"):format(self:GetTier(), "Invalid weapon", self:GetResult())
	end


	return ("T%d %s Blueprint"):format(self:GetTier(), wep.PrintName)
end

function bp:GetTransferCost()
	return self:GetBaseTransferCost() * (2 ^ (self:GetTier() - 1))
end

bp:Register()


function bp:GetWeaponType()
	return Inventory.Blueprints.WeaponPoolReverse[self:GetResult()]
end

include("blueprint_" .. Rlm(true) .. "_extension.lua")