local numCol, notNumCol, textCol = unpack(Inventory.Modifiers.DescColors)

local el; el = Inventory.BaseModifier:new("Venomous")
	:SetMaxTier(3)
	:SetMinBPTier(3)
	:SetPowerTier(3)

	:Hook("PostEntityTakeDamage", function(self, ent, dmg, took)
		if not IsPlayer(ent) or not took then return end
		if Venom.Active then return end

		local str = self:GetTierStrength(self:GetTier())
		if not str then return end
		str = str / 100

		local atk = dmg:GetAttacker()
		if not IsPlayer(atk) then return end

		ent:AddVenom(dmg:GetDamage() * str)
	end)

	:SetTierCalc(function(self, tier)
		return 10 + 5 * tier
	end)

--[[local recipes = {
	{"thruster_t1", 2},
	{"thruster_t2", 2},
	{"thruster_t2", 4},
}

el  :On("AlterRecipe", "a", function(self, itm, rec, tier)
		local itName = recipes[tier][1]
		rec[itName] = (rec[itName] or 0) + recipes[tier][2]
	end)]]


function el:GenerateMarkup(it, mup, tier)
	local mod = mup:AddPiece()
	mod:SetAlignment(1)
	mod.Font = "MRM24"

	local tx = mod:AddText("Venomous "  .. string.ToRoman(tier))
	mod:SetColor(Color(235, 80, 220))

	local desc = mup:AddPiece()
	desc.Font = "OS16"
	desc:DockMargin(8, 0, 8, 0)
	desc:SetColor(textCol)
	desc:SetAlignment(1)
	local tx = desc:AddText("Every time you deal damage, deal ")

	for i=1, self:GetMaxTier() do
		local tx2 = desc:AddText(tostring(self:GetTierStrength(i)) .. "%")
		tx2.color = i == tier and numCol or notNumCol

		if i ~= self:GetMaxTier() then
			local sep = desc:AddText("/")
			sep.color = notNumCol
		end
	end

	desc:AddText(" more as stackable venom.\nVenom ignores armor, but can be cured.")
end