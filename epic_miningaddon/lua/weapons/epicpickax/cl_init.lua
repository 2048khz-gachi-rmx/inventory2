include("shared.lua")

function SWEP:DrawHUD()

end

if IsValid(PickaxePanel) then PickaxePanel:Remove() end

function SWEP:Deploy()
	local sw, sh = ScrW(), ScrH()

	self.Deployed = true

	if not IsValid(self.Panel) then
		local p = vgui.Create("FFrame")
		local wid = sw / 1920 * 250
		--local hgt = sh / 1080 * 100
		p:SetAlpha(0)
		p:SetSize(wid, 16 + 24 + 8)
		p:SetPos(sw/2 + 16, sh / 2 - 16 / 2)

		p:On("ChangedSize", self.RepositionPanel, self)
		self.Panel = p
		p.Pickaxe = self
		p.BackgroundColor.a = 200
		p:SetCloseable(false, true)
		p.HeaderSize = 16

		p.PostPaint = self.PostPaint
		PickaxePanel = p
	end

end

function SWEP:PostPaint(w, h) --`self` is pnl

	if not IsValid(self.Pickaxe) or LocalPlayer():GetActiveWeapon() ~= self.Pickaxe then
		self:Remove()
		return
	end
	print(self:GetAlpha())
	local vein = self.Ore and self.Ore:IsValid() and self.Ore --yes

	local ores = (vein and vein.Ores) or self.Ores
	if not ores then return end --kk

	local total = (vein and (vein.TotalAmount or 1)) or self.TotalAmount
	local start = (vein and vein:GetStartingRichness()) or self.StartingRichness

	local fullw = w - 8

	local i = 0
	local x = 4

	for name, dat in pairs(ores) do
		i = i + 1
		local ore = dat.ore
		local amt = dat.amt
		local costamt = amt * ore:GetCost()

		local rectw = fullw / (costamt / total)

		local last = not next(ores, name)
		local name = ore:GetItemName()
		print(name, i, last, ore:GetOreColor())
		if i == 1 then
			draw.RoundedBoxEx(4, x, self.HeaderSize + 4, rectw, 24, ore:GetOreColor(), true, last, true, last)
			x = x + rectw
		elseif last  then
			draw.RoundedBoxEx(4, x, self.HeaderSize + 4, rectw, 24, ore:GetOreColor(), false, true, false, true)
			x = x + rectw
		else
			surface.SetDrawColor(ore:GetOreColor():Unpack())
			surface.DrawRect(x, self.HeaderSize + 4, rectw, 24)
			x = x + rectw
		end

	end
end

function SWEP.RepositionPanel(pnl, self, w, h)
	local sw, sh = ScrW(), ScrH()
	pnl.Y = sh/2 - h/2
end

function SWEP:Holster()

end

function SWEP:CLPrimaryAttack()

end

function SWEP:DrawHUD()
	local tr = LocalPlayer():GetEyeTrace()
	local pnl = self.Panel
	if not pnl:IsValid() then return end --ok

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
			self.StartingRichness = self.Ore:GetStartingRichness()
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