
local el; el = Inventory.BaseActiveModifier:new("MendGas")
	:SetMaxTier(3)
	:SetMinBPTier(3)
	:SetMaxBPTier(4)

	:SetTierCalc(function(self, tier)
		return 50 + tier * 25
	end)
	:SetCooldown(function(base, mod, ply)
		return 15
	end)

-- el.HealTotal = 100
el.TickInterval = 0.25
el.Radius = 128
el.Duration = 10

LibItUp.PlayerInfo.AliasNW("Mending", 101)
include("gas_ext_" .. Rlm() .. ".lua")