
local el; el = Inventory.BaseActiveModifier:new("MendGas")
	:SetMaxTier(3)
	:SetMinBPTier(3)
	:SetMaxBPTier(4)

	:SetTierCalc(function(self, tier)
		return 15 - 5 * tier -- 15/10/5
	end)
	:SetCooldown(function(base, mod, ply)
		return mod:GetTierStrength(mod:GetTier())
	end)

el.HealTotal = 100
el.TickInterval = 0.25
el.Radius = 128
el.Duration = 10

LibItUp.PlayerInfo.AliasNW("Mending", 101)
include("gas_ext_" .. Rlm() .. ".lua")