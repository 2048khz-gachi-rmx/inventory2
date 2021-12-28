
local el; el = Inventory.BaseActiveModifier:new("Sonar")
	:SetMaxTier(3)
	:SetMinBPTier(3)
	:SetMaxBPTier(4)

	:SetTierCalc(function(self, tier)
		return 1 -- ?
	end)



include("sonar_ext_" .. Rlm() .. ".lua")