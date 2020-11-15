include("shared.lua")

local OrePanel = {}

function SWEP:ValidatePanel()

	if not IsValid(PickaxePanel) then
		local sw, sh = ScrW(), ScrH()

		local p = vgui.Create("FFrame")
		local wid = sw / 1920 * 250
		--local hgt = sh / 1080 * 100
		p:SetAlpha(0)

		p:SetSize(wid, 16 + 24 + 8)
		p.OriginalHeight = 16 + 24 + 8

		p:SetPos(sw/2 + 16, sh / 2 - 16 / 2)

		p:On("ChangedSize", OrePanel.Reposition)

		p.Pickaxe = self
		p.BackgroundColor.a = 200
		p:SetCloseable(false, true)
		p.HeaderSize = 16
		p.Shadow = {alpha = 240, blur = 4}

		p.Animatable = Animatable:new()

		p.PostPaint = OrePanel.PostPaint
		PickaxePanel = p
	end

end

if IsValid(PickaxePanel) then PickaxePanel:Remove() end

function SWEP:Deploy()
	self.Deployed = true
	self:ValidatePanel()
end

function OrePanel:PaintOreBar(w, h, vein, ores)
	local x = 4
	local y = self.HeaderSize + 4

	local total = (vein and (vein.TotalAmount or 1)) or self.TotalAmount

	local fullw = w - 8
	local costw = fullw / total --width per 1 ore-cost

	local i = 0
	local anim = self.Animatable

	for name, dat in pairs(ores) do
		i = i + 1
		local ore = dat.ore
		local amt = dat.amt
		local start = dat.startamt

		local cost = ore:GetCost()
		local costamt = amt * cost

		local rectw = costw * costamt

		anim:MemberLerp(dat, "RectW", rectw, 0.3, 0, 0.4)

		rectw = math.floor(dat.RectW or rectw)

		local missingw = (costw * start * cost) - rectw

		--local missingw = costw * cost * missing
		--anim:MemberLerp(dat, "MissingW", missingw, 0.3, 0, 0.4)
		--missingw = math.ceil(dat.MissingW or missingw)

		local last = not next(ores, name)

		if not ore.MissingOreColor then
			ore.MissingOreColor = ore:GetOreColor():Copy()
			ore.MissingOreColor.a = 140
		end

		local missingcol = ore.MissingOreColor
		--print("missing:", missingw, name)
		if i == 1 then
			--print(missingw, rectw)
			local roundRight = missingw == 0 and last

			draw.RoundedBoxEx(4, x, y, rectw, 24, ore:GetOreColor(), true, roundRight, true, roundRight)
			x = x + rectw

			if missingw > 0 then
				if last then
					draw.RoundedBoxEx(4, x, y, missingw, 24, missingcol, false, true, false, true)
				else
					surface.SetDrawColor(missingcol:Unpack())
					surface.DrawRect(x, y, missingw, 24)
				end

				x = x + missingw
			end

		elseif last then

			local roundRight = missingw == 0
			draw.RoundedBoxEx(4, x, self.HeaderSize + 4, rectw, 24, ore:GetOreColor(), false, roundRight, false, roundRight)
			x = x + rectw

			if missingw > 0 then
				draw.RoundedBoxEx(4, x, y, missingw, 24, missingcol, false, true, false, true)

				x = x + missingw
			end

		else
			surface.SetDrawColor(ore:GetOreColor():Unpack())
			surface.DrawRect(x, self.HeaderSize + 4, rectw, 24)
			x = x + rectw

			if missingw > 0 then
				surface.SetDrawColor(missingcol:Unpack())
				surface.DrawRect(x, y, missingw, 24)

				x = x + missingw
			end

		end

	end
end

function OrePanel:PaintOreText(w, h, vein, ores)
	local needh = self.OriginalHeight + table.Count(ores) * 24 + 4

	local anim, new = self:To("Height", needh, 0.3, 0, 0.2)

	if new then
		anim:On("Think", function()
			self:SetTall(self.Height)
		end)
	end

	surface.SetFont("OSB20")
	local tx_template = "%s:  x%d"
	local y = self.OriginalHeight + 4

	for k,v in pairs(ores) do


		local ore, amt = v.ore, v.amt
		local tx = tx_template:format(ore:GetName(), amt)

		surface.SetTextColor(ore:GetOreColor():Unpack())
		local tw, th = surface.GetTextSize(tx)
		surface.SetTextPos(w/2 - tw/2, y)
		surface.DrawText(ore:GetName() .. ":  ")
		surface.SetTextColor(color_white)
		surface.DrawText("x" .. amt)
		y = y + th
	end

end

function OrePanel:PostPaint(w, h)

	if not IsValid(self.Pickaxe) or LocalPlayer():GetActiveWeapon() ~= self.Pickaxe then
		self:Remove()
		return
	end

	if self:GetAlpha() == 0 then return end --???

	local vein = self.Ore and self.Ore:IsValid() and self.Ore --yes

	local ores = (vein and vein.Ores) or self.Ores
	if not ores then return end --kk

	OrePanel.PaintOreBar(self, w, h, vein, ores)
	OrePanel.PaintOreText(self, w, h, vein, ores)
end

function OrePanel:Reposition(w, h)
	local sw, sh = ScrW(), ScrH()
	self.Y = sh/2 - h/2
end

function SWEP:Holster()

end

function SWEP:CLPrimaryAttack()

end

function SWEP:DrawHUD()
	local tr = LocalPlayer():GetEyeTrace()
	self:ValidatePanel()

	local pnl = PickaxePanel

	if not tr.Hit or not tr.Entity.IsOre or tr.Fraction * 32768 > 128 then

		local anim, new = pnl:To("Alpha", 0, 0.2, 0, 1.9)

		if new then
			anim:On("Think", function(_, fr)
				pnl:SetAlpha(pnl.Alpha)
			end)
		end

		if self.Ore and self.Ore:IsValid() then
			self.Ores = self.Ore.Ores
			self.TotalAmount = self.Ore.TotalAmount or 1
		else
			self.Ore = nil
			self.Ores = nil
		end

		return
	end

	local anim, new = pnl:To("Alpha", 255, 0.2, 0, 0.3)

	if new then
		anim:On("Think", function(_, fr)
			pnl:SetAlpha(pnl.Alpha)
		end)
	end

	pnl.Ore = tr.Entity

end