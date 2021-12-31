local numCol, notNumCol, textCol = unpack(Inventory.Modifiers.DescColors)

local curMod; curMod = Inventory.BaseModifier:new("Vampiric")
	:SetMaxTier(3)
	:SetMinBPTier(3)
	:SetPowerTier(2)
	:Hook("PostEntityTakeDamage", function(self, ent, dmg)
		if not IsPlayer(ent) then return end

		local str = self:GetTierStrength(self:GetTier())
		if not str then return end
		str = str / 100

		local atk = dmg:GetAttacker()
		if not IsPlayer(atk) then return end

		local regen = dmg:GetDamage() * str
		atk:AddHealth(regen)
	end)
	:SetTierCalc(function(self, tier)
		return tier * 10
	end)

function curMod:GenerateMarkup(it, mup, tier)
	local mod = mup:AddPiece()
	mod:SetAlignment(1)
	mod.Font = "MRB24"

	local tx = mod:AddText("Vampiric "  .. string.ToRoman(tier))
	mod:SetColor(Color(80, 220, 95))

	local desc = mup:AddPiece()
	desc.Font = "OS16"
	desc:DockMargin(8, 0, 8, 0)
	desc:SetColor(textCol)
	desc:SetAlignment(1)

	local tx = desc:AddText("Steal ")

	for i=1, self:GetMaxTier() do
		local tx2 = desc:AddText(tostring(self:GetTierStrength(i)))
		tx2.color = i == tier and numCol or notNumCol

		if i ~= self:GetMaxTier() then
			local sep = desc:AddText("/")
			sep.color = notNumCol
		end
	end
	desc:AddText("% of damage dealt as health.")
end

