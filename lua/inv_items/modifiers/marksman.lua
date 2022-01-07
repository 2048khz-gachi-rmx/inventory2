local numCol, notNumCol, textCol = unpack(Inventory.Modifiers.DescColors)

local pow = {
	4, 5, 6
}

local cap = {
	16, 25, 30
}

local el; el = Inventory.BaseModifier:new("Marksman")
	:SetMaxTier(3)
	:SetMinBPTier(2)
	:SetMaxBPTier(4)
	:SetPowerTier(2)
	:SetTierCalc(function(self, tier)
		return pow[tier], cap[tier]
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
	mod.Font = "EXSB20"

	local tx = mod:AddText("Marksman " .. string.ToRoman(tier))
	mod:SetColor(Color(220, 60, 60))

	local desc = mup:AddPiece()
	desc.Font = "OS16"
	desc:DockMargin(8, 0, 8, 0)
	desc:SetColor(textCol)
	desc:SetAlignment(1)

	desc:AddText("Deal ")

	for i = 1, self:GetMaxTier() do
		local stack = tostring(self:GetTierStrength(i))
		local tx2 = desc:AddText(stack .. "%")
		tx2.color = numCol
		tx2.color = i == tier and numCol or notNumCol

		if i ~= self:GetMaxTier() then
			local sep = desc:AddText("/")
			sep.color = notNumCol
		end
	end

	desc:AddText(" more damage for each shot you hit, up to ")

	for i = 1, self:GetMaxTier() do
		local _, cap = self:GetTierStrength(i)
		local tx2 = desc:AddText(cap .. "%")
		tx2.color = numCol
		tx2.color = i == tier and numCol or notNumCol

		if i ~= self:GetMaxTier() then
			local sep = desc:AddText("/")
			sep.color = notNumCol
		end
	end

	desc:AddText(" extra damage. Bonus decreases over time or on missed shots, " ..
		" depending on damage.")
end


include("marksman_ext_" .. Rlm() .. ".lua")
