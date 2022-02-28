local PANEL = {}

function PANEL:Init()
	self.Good = {}
	self.Bad = {}
	self.Font = "EXSB18"
	self.ExtraFont = "EXM14"

	if input.IsControlDown() then
		self.InfoFrac = 1
		self:Paint(self:GetSize())
	end
end

ChainAccessor(PANEL, "Item", "Item")

function PANEL:RecalcStats()
	local itm = self.Item
	local good = {}
	local bad = {}

	for k,v in pairs(itm:GetStats()) do
		local numTxt, _, is_good = Inventory.Stats.NegPos(k, v)

		if is_good then
			good[#good + 1] = {
				numTxt, v, k, -- [1] - [3]
				nil, -- [4] = statName,
				Inventory.Stats.ToRoll(itm:GetQuality(), k, v) -- [5], [6], [7] = statRoll, statMin, statMax
				}
		else
			bad[#bad + 1] = {
				numTxt, v, k,
				nil,
				Inventory.Stats.ToRoll(itm:GetQuality(), k, v)
			}
		end
	end

	table.sort(good, function(a, b) return a[5] > b[5] end)
	table.sort(bad, function(a, b) return a[5] > b[5] end)

	surface.SetFont(self.Font)

	local maxGood, maxBad = 0, 0

	for k,v in ipairs(good) do
		local txt = Inventory.Stats.ToName(v[3])
		v[4] = txt
		maxGood = math.max(maxGood, (surface.GetTextSize(txt)))
	end

	for k,v in ipairs(bad) do
		local txt = Inventory.Stats.ToName(v[3])
		v[4] = txt
		maxBad = math.max(maxBad, (surface.GetTextSize(txt)))
	end

	local maxW = math.max(maxGood, maxBad)

	self.Good = good
	self.Bad = bad
	self.MaxWGood, self.MaxWBad, self.MaxWAll = maxGood, maxBad, maxW

	local statH = draw.GetFontHeight(self.Font)
	self:SetTall(statH * (#good + #bad) + 4)
	self:InvalidateParent(true)
end

function PANEL:SetItem(itm)
	self.Item = itm
	self:RecalcStats()
end

local skyBord = Colors.Sky:Copy():MulHSV(1, 1.2, 0.7)
local empty = Color(40, 40, 40)

local bad = Color(210, 70, 70)
local badBord = bad:Copy():MulHSV(1, 1.2, 0.7)

local textDat = {
	Filled = color_white,
	Unfilled = Color(135, 135, 135),
	Text = "Bruh momento",
	Font = "EXSB16"
}

function PANEL:Paint(w, h)
	if not self.Item then return end

	self:To("InfoFrac", input.IsControlDown(), 0.3, 0, 0.3)

	local y = 0

	local fH = draw.GetFontHeight(self.Font)
	local xfH = draw.GetFontHeight(self.ExtraFont)
	local ifr = self.InfoFrac or 0

	local barH = math.floor(fH * 0.8)
	local barY = math.floor(fH / 2 - barH / 2)

	local barW = w - self.MaxWAll - 8 - 16

	surface.SetDrawColor(30, 80, 30)
	for k,v in ipairs(self.Good) do
		local num, stat, statID, statName, roll, min, max = unpack(v)

		draw.SimpleText2(statName, self.Font, 8, y, color_white, 0)
		textDat.Text = num
		--surface.DrawRect(self.MaxWAll + 16, y + barY, w - self.MaxWGood - 8 - 16, barH)
		DarkHUD.PaintBar(4,
			self.MaxWAll + 16, y + barY, barW, barH,
			roll, empty, skyBord, Colors.Sky, textDat, true)

		local add = xfH * ifr
		if ifr > 0 then
			local r, g, b = textDat.Unfilled:Unpack()
			surface.SetTextColor(r, g, b, ifr * 250)

			if Inventory.Stats.IsGood(stat) then
				local temp = max
				max = min
				min = temp
			end

			draw.SimpleText2(min, self.ExtraFont,
				self.MaxWAll + 16, y + fH * 0.675 + fH * 0.2 * ifr, nil, 0)

			draw.SimpleText2(max, self.ExtraFont,
				self.MaxWAll + 16 + barW, y + fH * 0.675 + fH * 0.2 * ifr, nil, 2)
		end

		y = y + fH + add
	end

	y = y + 8

	for k,v in ipairs(self.Bad) do
		local num, stat, statID, statName, roll, min, max = unpack(v)
		textDat.Text = num

		draw.SimpleText2(statName, self.Font, 8, y, color_white, 0)
		--surface.DrawRect(self.MaxWAll + 16, y + barY, w - self.MaxWAll - 8 - 16, barH)
		roll = 1 - roll
		DarkHUD.PaintBar(4,
			self.MaxWAll + 16, y + barY, barW, barH,
			roll, empty, badBord, bad, textDat, nil, true)

		local add = xfH * ifr

		if ifr > 0 then
			local r, g, b = textDat.Unfilled:Unpack()
			surface.SetTextColor(r, g, b, ifr * 250)

			if Inventory.Stats.IsGood(stat) then
				local temp = max
				max = min
				min = temp
			end

			draw.SimpleText2(min, self.ExtraFont,
				self.MaxWAll + 16, y + fH * 0.675 + fH * 0.2 * ifr, nil, 0)

			draw.SimpleText2(max, self.ExtraFont,
				self.MaxWAll + 16 + barW, y + fH * 0.675 + fH * 0.2 * ifr, nil, 2)
		end

		y = y + fH + add
	end

	self:SetTall(y)
end

vgui.Register("ItemStats", PANEL, "Panel")