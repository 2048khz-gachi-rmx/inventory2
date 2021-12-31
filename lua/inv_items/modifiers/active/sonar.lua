
local el; el = Inventory.BaseActiveModifier:new("Sonar")
	:SetMaxTier(3)
	:SetMinBPTier(3)
	:SetMaxBPTier(4)

	:SetTierCalc(function(self, tier)
		return 20 - 5 * tier -- 15/10/5
	end)
	:SetCooldown(function(base, mod, ply)
		return mod:GetTierStrength(mod:GetTier())
	end)

el.ServoTimer = 0.25
el.FireTimer = 0.8

include("sonar_ext_" .. Rlm() .. ".lua")