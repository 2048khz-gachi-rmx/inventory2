
local el; el = Inventory.BaseActiveModifier:new("MendGas")
	:SetMaxTier(3)
	:SetMinBPTier(3)
	:SetMaxBPTier(4)

	:SetTierCalc(function(self, tier)
		return 20 - 5 * tier -- 15/10/5
	end)
	:SetCooldown(function(base, mod, ply)
		return mod:GetTierStrength(mod:GetTier())
	end)

el.HealTotal = 75
el.TickInterval = 0.25
el.Radius = 128
el.Duration = 5

include("gas_ext_" .. Rlm() .. ".lua")