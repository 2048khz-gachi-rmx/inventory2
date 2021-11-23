--?

local eq = Inventory.GetClass("base_items", "equipment")
local wep = eq:ExtendItemClass("Weapon", "Weapon")

wep.Uses = 150
wep.Tiers = {1, 5}

ChainAccessor(wep, "WeaponClass", "WeaponClass")
function wep:SetTiers(min, max)
	min = math.min(min or 1, max or 5)
	max = math.max(min or 1, max or 5)

	self.Tiers = {min, max}
end

function wep:CanGenerate(tier)
	local trs = self:GetTiers()
	return tier >= trs[1] and tier <= trs[2]
end

ChainAccessor(wep, "Tiers", "Tiers", true)

wep:Register()
wep:NetworkVar("UInt", "Uses", 16)
--Inventory.RegisterClass("Weapon", wep, Inventory.BaseItemObjects)
