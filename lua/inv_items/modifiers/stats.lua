local numCol, notNumCol, textCol = unpack(Inventory.Modifiers.DescColors)

local function retMark(self, it, mup, tier)
	local mod = mup:AddPiece()
	mod:SetAlignment(1)
	mod:SetFont("EXSB24")
	mod:AddText(self._name .. " " .. string.ToRoman(tier))

	mod:SetColor(self._col)

	local desc = mup:AddPiece()
	desc.Font = "OS16"
	desc:DockMargin(8, 0, 8, 0)
	desc:SetColor(textCol)
	desc:SetAlignment(1)

	if self.GenerateDescription then
		self:GenerateDescription(it, mup, tier, desc)
	elseif self._desc then
		local tx = desc:AddText(self._desc)
	end

end

local curMod
local function make(nm, col, desc)
	local t = istable(nm) and nm or {nm, nm}

	local mod = Inventory.BaseModifier:new(t[1])
	curMod = mod
	curMod._col = col
	curMod._name = t[2]
	curMod._desc = desc
	curMod.GenerateMarkup = retMark

	return mod
end


make({"Accurate", "Precise"}, Color(220, 230, 100))
	:SetMaxTier(3)
	:SetMinBPTier(1)
	:SetMaxBPTier(2)

	:SetModStats({
		Spread = function(self)
			return -self:GetTierStrength(self:GetTier())
		end,
	})

	-- 15 30 50
	:SetTierCalc(function(_, t)
		return 15 * t + math.max(0, t - 2) * 5
	end)

	function curMod:GenerateDescription(it, mup, tier, desc)
		local tx = desc:AddText("Reduce spread by ")

		for i=1, self:GetMaxTier() do
			local tx2 = desc:AddText(tostring(self:GetTierStrength(i)) .. "%")
			tx2.color = i == tier and numCol or notNumCol

			if i ~= self:GetMaxTier() then
				local sep = desc:AddText("/")
				sep.color = notNumCol
			end
		end
		desc:AddText(".")
	end

make("Stabilized", Color(105, 220, 200))
	:SetMaxTier(2)
	:SetMinBPTier(1)
	:SetMaxBPTier(2)

	:SetTierCalc(function(_, t)
		return 30 + 20 * t
	end)

	:SetModStats({
		Recoil = function(self)
			return -self:GetTierStrength(self:GetTier())
		end,

		--[[RecoilSide = function(self)
			local _, r2 = self:GetTierStrength(self:GetTier())

			return -r2
		end,]]

		RecoilPunch = function(self)
			return -self:GetTierStrength(self:GetTier())
		end,
	})

	function curMod:GenerateDescription(it, mup, tier, desc)
		local tx = desc:AddText("Reduce recoil by ")
		local vrecs, hrecs = {}, {}

		for i=1, self:GetMaxTier() do
			vrecs[i], hrecs[i] = self:GetTierStrength(i)
		end

		for i=1, self:GetMaxTier() do
			local tx2 = desc:AddText(tostring(vrecs[i]) .. "%")
			tx2.color = i == tier and numCol or notNumCol

			if i ~= self:GetMaxTier() then
				local sep = desc:AddText("/")
				sep.color = notNumCol
			end
		end

		--[[desc:AddText(" and horizontal recoil by ")

		for i=1, self:GetMaxTier() do
			local tx2 = desc:AddText(tostring(hrecs[i]) .. "%")
			tx2.color = i == tier and numCol or notNumCol

			if i ~= self:GetMaxTier() then
				local sep = desc:AddText("/")
				sep.color = notNumCol
			end
		end]]

		desc:AddText(".")
	end

make("Capacious", Color(230, 90, 20))
	:SetMaxTier(3)
	:SetMinBPTier(2)
	:SetMaxBPTier(4)

	:SetTierCalc(function(_, t) return 25 + 15 * t end)

	:SetModStats({
		ClipSize = function(self)
			return self:GetTierStrength(self:GetTier())
		end,
	})

	function curMod:GenerateDescription(it, mup, tier, desc)
		desc:AddText("Increase magazine capacity by ")

		for i=1, self:GetMaxTier() do
			local tx2 = desc:AddText(tostring(self:GetTierStrength(i)) .. "%")
			tx2.color = i == tier and numCol or notNumCol

			if i ~= self:GetMaxTier() then
				local sep = desc:AddText("/")
				sep.color = notNumCol
			end
		end

		desc:AddText(".")
	end

make("Agile", Color(20, 200, 230))
	:SetMaxTier(3)
	:SetMinBPTier(2)
	:SetMaxBPTier(4)

	:SetTierCalc(function(_, t) return 20 + 10 * t end)

	:SetModStats({
		ReloadTime = function(self)
			return -self:GetTierStrength(self:GetTier())
		end,
	})

	function curMod:GenerateDescription(it, mup, tier, desc)
		desc:AddText("Reduce reloading time by ")

		for i=1, self:GetMaxTier() do
			local tx2 = desc:AddText(tostring(self:GetTierStrength(i)) .. "%")
			tx2.color = i == tier and numCol or notNumCol

			if i ~= self:GetMaxTier() then
				local sep = desc:AddText("/")
				sep.color = notNumCol
			end
		end

		desc:AddText(".")
	end