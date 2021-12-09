local uq = Inventory.ItemObjects.Unique

function uq:GenerateModifiersText(cloud, markup, needSep)
	if table.IsEmpty(self:GetModifiers()) then return end

	markup:SetWide(math.max(markup:GetWide(), 300))

	if needSep then
		cloud:AddSeparator(nil, cloud.LabelWidth / 8, 4)
	end

	for k,v in pairs(self:GetModifiers()) do
		local mod = Inventory.Modifiers.Get(k)
		if mod then
			mod:GenerateMarkup(self, markup, v)
		else
			local mpiece = markup:AddPiece()
			mpiece:AddText(k).IgnoreVisibility = true
			mpiece:SetAlignment(1)
			mpiece:Debug()
		end
	end

	return needSep
end

function uq:GenerateStatsText(cloud, markup)
	local good = {}
	local bad = {}

	for k,v in pairs(self:GetStats()) do
		local numTxt, col, is_good = Inventory.Stats.NegPos(k, v)

		if is_good then
			good[#good + 1] = {numTxt, col, v, k}
		else
			bad[#bad + 1] = {numTxt, col, v, k}
		end
	end

	table.sort(good, function(a, b) return a[3] > b[3] end)
	table.sort(bad, function(a, b) return a[3] < b[3] end)

	for k,v in ipairs(good) do
		local txt = ("%s %s"):format(v[1], Inventory.Stats.ToName(v[4]))
		local font = "OS18"
		cloud:AddFormattedText(txt, v[2], font, nil, nil, 1)
	end

	for k,v in ipairs(bad) do
		local txt = ("%s %s"):format(v[1], Inventory.Stats.ToName(v[4]))
		local font = "OS18"
		cloud:AddFormattedText(txt, v[2], font, nil, nil, 1)
	end

	return #good > 0 or #bad > 0
end

function uq:GetRarityColor()
	return self:GetRarity():GetColor()
end

function uq:GetRarityText()
	return self:GetRarity():GetName()
end

function uq:GenerateRarityText(cloud, markup)
	local pnl = cloud:AddPanel(vgui.Create("DPanel"))
	pnl:SetTall(20)

	local itm = self
	local col = self:GetRarityColor()
	local txCol = (col or color_white):Copy()

	txCol:MulHSV(1, 0.7, 1)
		:ModHSV(0, 0, 0.4)

	function pnl:Paint(w, h)
		if not IsValid(cloud) then print("!?") return end
		local col = col
		if not col then col = ColorRand() end -- bad; no color found

		surface.SetDrawColor(col.r, col.g, col.b, col.a * 0.7)

		surface.SetMaterial(MoarPanelsMats.gr)
		surface.DrawTexturedRect(0, 0, w / 2, h)

		surface.SetMaterial(MoarPanelsMats.gl)
		surface.DrawTexturedRect(w / 2, 0, w / 2, h)

		local tx = itm:GetRarityText()
		local font = Fonts.PickFont("BSB", tx, w - 16, 22, 22)
		local bfn = Fonts.GenerateBlur(font, 4)

		draw.SimpleText(tx, bfn, w / 2, h / 2, color_black, 1, 1)
		draw.SimpleText(tx, font, w / 2, h / 2, txCol, 1, 1)
	end
end

uq.AutoSepNum = 1 -- after the rarity panel

function uq:PostGenerateText(cloud, markup) end

function uq:GenerateText(cloud, markup)
	cloud:SetMaxW( math.max(cloud:GetItemFrame():GetWide() * 2.5, cloud:GetMaxW()) )
	self:GenerateRarityText(cloud, markup)
	local needSep = self:GenerateStatsText(cloud, markup)
	needSep = self:GenerateModifiersText(cloud, markup, needSep)
end


uq:On("GenerateText", "Modifiers", function(self, cloud, markup)
	self:GenerateText(cloud, markup)
end)

uq:On("PostGenerateText", "Recipe", function(self, cloud, markup)
	self:PostGenerateText(cloud, markup)
end)