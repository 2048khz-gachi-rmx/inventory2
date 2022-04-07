local numCol, notNumCol, textCol = unpack(Inventory.Modifiers.DescColors)
local dmgMult = 1.35

local el; el = Inventory.BaseModifier:new("Executioner")
	:SetMaxTier(3)
	:SetMinBPTier(2)
	:SetMaxBPTier(4)
	:SetPowerTier(2)
	:Hook("EntityTakeDamage", function(self, ent, dmg)
		if not ent:IsPlayer() then return end

		local hp, ar = ent:Health(), ent:Armor()
		local total = hp + ar

		local str = self:GetTierStrength(self:GetTier())
		if not str then return end

		if total > str then return end

		dmg:ScaleDamage(dmgMult)
	end)
	:SetTierCalc(function(self, tier)
		-- 50 / 75 / 100
		return 25 + tier * 25
	end)

--[=[
local recipes = {
	{"thruster_t1", 2},
	{"thruster_t2", 2},
	{"thruster_t2", 4},
}

el  :On("AlterRecipe", "a", function(self, itm, rec, tier)
		rec[recipes[tier][1]] = recipes[tier][2]
	end)
]=]

function el:GenerateMarkup(it, mup, tier)
	local mod = mup:AddPiece()
	mod:SetAlignment(1)
	mod.Font = "WEIRD20"

	local tx = mod:AddText("Executioner " .. string.ToRoman(tier))
	mod:SetColor(Color(220, 60, 60))

	local desc = mup:AddPiece()
	desc.Font = "OS16"
	desc:DockMargin(8, 0, 8, 0)
	desc:SetColor(textCol)
	desc:SetAlignment(1)

	desc:AddText("Deal ")
	desc:AddText(dmgMult * 100 - 100 .. "% ").color = numCol
	desc:AddText("more damage to players below ")

	for i=1, self:GetMaxTier() do
		local tx2 = desc:AddText(tostring(self:GetTierStrength(i)))
		tx2.color = i == tier and numCol or notNumCol

		if i ~= self:GetMaxTier() then
			local sep = desc:AddText("/")
			sep.color = notNumCol
		end
	end

	desc:AddText(" combined health.")
end