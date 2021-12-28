--
local numCol, notNumCol, textCol = unpack(Inventory.Modifiers.DescColors)

local activeCol = Color(255, 255, 255)
local inactiveCol = Offhand.InactiveColor
local col = inactiveCol:Copy()

local handle = BSHADOWS.GenerateCache("Mod_Sonar", 128, 128)
handle:SetGenerator(function(self, w, h)
	Icon("https://i.imgur.com/OjieIw3.png", "beacon.png")
		:SetSize(w, h)
		:Paint(0, 0, w, h)
end)

handle.cached = false

local el = Inventory.Modifiers.Pool.Sonar
	:SetIcon(Icon("https://i.imgur.com/OjieIw3.png", "beacon.png"):SetSize(64, 64))
	:SetPaint(function(base, fr, x, y, sz)
		if not handle.cached then
			handle:CacheShadow(4, 8, 4)
			handle.cached = true
		end

		local mod = base:GetModFromPlayer(LocalPlayer())
		fr:To("SonarAcFr", mod and 1 or 0, 0.3, 0, 0.3)
		local acf = fr.SonarAcFr or 0
		draw.LerpColor(acf, col, activeCol, inactiveCol)

		local icc = base:GetIconCopy()
		icc:SetColor(col)

		handle:Paint(x, y, sz, sz)
		icc:Paint(x, y, sz, sz)
		-- print(col, acf, mod)
	end)

	:SetOnActivate(function(base)
		local mod = base:GetModFromPlayer(LocalPlayer())
		if not mod then return end

		local pr = base:RequestAction()
		pr:Then(function()
			
		end)
	end)

el:SetDescription("Fire a sonar beacon, revealing nearby enemies.")
function el:GenerateMarkup(it, mup, tier)
	local mod = mup:AddPiece()
	mod:SetAlignment(1)
	mod.Font = "OS20"

	local tx = mod:AddText("Sonar " .. string.ToRoman(tier))
	mod:SetColor(Color(220, 60, 60))

	local desc = mup:AddPiece()
	desc.Font = "OS16"
	desc:DockMargin(8, 0, 8, 0)
	desc:SetColor(textCol)
	desc:SetAlignment(1)

	desc:AddText("NYI lol ")
	--desc:AddText(dmgMult * 100 - 100 .. "% ").color = numCol
	desc:AddText("brrt ")

	for i=1, self:GetMaxTier() do
		local tx2 = desc:AddText(tostring(self:GetTierStrength(i)))
		tx2.color = i == tier and numCol or notNumCol

		if i ~= self:GetMaxTier() then
			local sep = desc:AddText("/")
			sep.color = notNumCol
		end
	end

	desc:AddText(" bwrwrrw")
end