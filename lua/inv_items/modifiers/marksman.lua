local numCol, notNumCol, textCol = unpack(Inventory.Modifiers.DescColors)

local pow = {
	5, 8, 12
}

local cap = {
	20, 40, 60
}

local el; el = Inventory.BaseModifier:new("Marksman")
	:SetMaxTier(3)
	:SetMinBPTier(2)
	:SetMaxBPTier(4)
	:SetPowerTier(2)
	:Hook("EntityTakeDamage", function(self, ent, dmg)
		if not ent:IsPlayer() then return end

		local str, cap = self:GetTierStrength(self:GetTier())
		if not str then return end

		local bonus = math.min(cap, str * self._marksmanHits) / 100 + 1
		dmg:ScaleDamage(bonus)

	end)
	:SetTierCalc(function(self, tier)
		return pow[tier], cap[tier]
	end)

hook.Add("ArcCW_BulletLanded", "MarksmanMod", function(wep, pen)
	local wdat = wep:GetWeaponData()
	if not wdat then return end

	local mods = wdat:GetMods()
	if not mods[el:GetName()] then return end

	local mod = mods[el:GetName()]

	local has_ply = false
	local maxDmg = 0

	local add, stk = mod:GetTierStrength(mod:GetTier())
	local maxHits = stk / add

	local t = (mod._lastMarksman or CurTime())
	local passed = CurTime() - t


	local msh = mod._marksmanHits or 0


	if passed > 3 then
		msh = math.max(0, msh - (passed - 3))
	end

	for eid, dmg in pairs(pen) do
		if Entity(eid):IsPlayer() and dmg > 0 then
			msh = math.min(
				msh + 1,
				maxHits
			)

			mod._lastMarksman = CurTime()
			has_ply = true
		else
			maxDmg = math.max(maxDmg, dmg)
		end
	end

	if maxDmg == 0 then
		maxDmg = wep:GetDamage(128, true)
	end

	if not has_ply then
		msh = math.max(0, (msh or 0) - math.min(1.5, maxDmg / 25))
	end

	mod._marksmanHits = msh
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