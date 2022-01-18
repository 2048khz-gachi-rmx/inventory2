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

local mdl
local anim = Animatable("sonar")
anim.Frac = 0

function el:StartCannon()
	if not mdl then
		mdl = ClientsideModel("models/combine_turrets/ceiling_turret.mdl")
	end

	mdl:SetNoDraw(true)
	mdl.active = true
	anim:To("Frac", 1, 0.8, 0, 1)
end

function el:EndCannon()
	mdl.active = false
	anim:To("Frac", 0, 0.6, 0, 1)
end

el:SetIcon(Icon("https://i.imgur.com/OjieIw3.png", "beacon.png"):SetSize(64, 64))
:SetPaint(function(base, fr, x, y, sz)
	if not handle.cached then
		handle:CacheShadow(4, 8, 4)
		handle.cached = true
	end


	local mod = base:GetModFromPlayer(LocalPlayer())
	local allcd = mod and eval(base:GetCooldown(), base, mod, LocalPlayer()) or 1
	local cdFrac = mod and 1 - (math.max(0, (mod:GetCooldown() or 0) - CurTime()) / allcd) or 1

	local frTo = mod and 1 or 0
	frTo = frTo * (cdFrac == 1 and 1 or 0.2)

	fr:To("SonarAcFr", frTo, 0.3, 0, 0.3)

	local acf = fr.SonarAcFr or 0
	draw.LerpColor(acf, col, activeCol, inactiveCol)

	local icc = base:GetIconCopy()
	icc:SetColor(col)

	handle:Paint(x, y, sz, sz)

	local fsz = sz * cdFrac
	local mx = math.floor(x + sz / 2 - fsz / 2)

	White()
	draw.BeginMask()
	--draw.SetMaskDraw(true)
		surface.DrawRect(mx, y, math.ceil(fsz), sz)
	draw.DrawOp()
		icc:Paint(x, y, sz, sz)
	draw.FinishMask()

	
	-- print(col, acf, mod)
end)

:SetOnActivate(function(base, me, mod)
	local pr = base:RequestAction(mod)
	me:EmitSound("test/deploy" .. math.random(1, 3) .. ".mp3", 50, math.random(90, 110), 0.7)

	me:LiveTimer("SonarServo", base.ServoTimer, function()
		me:EmitSound("test/servo" .. math.random(1, 3) .. ".mp3", 50, math.random(100, 100), 0.7)
	end)

	base:StartCannon()

	me:Timer("SonarCannon", base.FireTimer, function()
		anim.FireFrac = 0

		anim:To("FireFrac", 1, 0.02, 0, 1, true):Then(function()
			anim:To("FireFrac", 0, 0.7, 0.1, 0.4, true)
		end)

		me:Timer("SonarCannonRetract", 1, function()
			ply:EmitSound("test/finish" .. math.random(1, 3) .. ".mp3",
				50, math.random(90, 110), 0.7)

			base:EndCannon()
		end)
	end)

	pr:Then(function()
		-- ?
	end, function()
		-- failed for some reason
		me:EmitSound("buttons/button11.wav", 50)
		me:RemoveTimer("SonarServo")
		me:RemoveTimer("SonarCannon")
		base:EndCannon()
	end)
end)

el:SetDescription("Fire a sonar beacon, revealing nearby enemies.")
function el:GenerateMarkup(it, mup, tier)
	local mod = mup:AddPiece()
	mod:SetAlignment(1)
	mod.Font = "EXB28"

	local tx = mod:AddText("Sonar " .. string.ToRoman(tier))
	mod:SetColor(Color(220, 210, 60))

	local desc = mup:AddPiece()
	desc.Font = "OS16"
	desc:DockMargin(8, 0, 8, 0)
	desc:SetColor(textCol)
	desc:SetAlignment(1)

	desc:AddText("Fire a destructible sonar beacon, which highlights enemies within its' radius " ..
		" even through walls. Cooldown: ")

	for i=1, self:GetMaxTier() do
		local tx2 = desc:AddText(tostring(self:GetTierStrength(i)))
		tx2.color = i == tier and numCol or notNumCol

		if i ~= self:GetMaxTier() then
			local sep = desc:AddText("/")
			sep.color = notNumCol
		end
	end

	desc:AddText("s.")
end

hook.Add("PostDrawViewModel", "SonarCam", function()
	if not mdl or anim.Frac == 0 then return end

	-- unoptimized? dont care! eat megashitdicks!!!!!!

	cam.Start3D(EyePos(), EyeAngles(), 60)
	cam.IgnoreZ(true)
	mdl:SetNoDraw(false)

	local ep = EyePos()
	local ev = EyeVector()
	local ea = EyeAngles()

	local fr = anim.Frac
	local right = mdl.active and -16 - 16 * (1 - math.min(1, Ease(fr, 0.4) / 0.4)) or -16

	mdl:SetPos(EyePos()
		+ ea:Right() * right
		+ ev * 56
		+ ea:Up() * 4
		)
	mdl:SetAngles(ea)
	

	local base_fr = mdl.active and math.min(1, fr / 0.4) or fr

	local ffr = anim.FireFrac or 0
	local side = mdl.active and Ease(fr, 0.2) or 1

	--local top_fr = math.Remap(fr, 0, 1, )

	if mdl.active then
		mdl:ManipulateBoneAngles(0, Angle(0, 0, -170 + Ease(base_fr, 0.2) * 90))
	else
		mdl:ManipulateBoneAngles(0, Angle(0, 0, -80 - Ease((1 - fr), 3.2) * 110))
	end

	--mdl:ManipulateBoneAngles(1, Angle(0, 0, -45 + side * 45))

	if mdl.active then
		mdl:ManipulateBoneAngles(2, Angle(0, 0, -120 + Ease(fr, 0.2) * 120 - 10 * ffr))
	else
		mdl:ManipulateBoneAngles(2, Angle(0, 0, Ease((1 - fr), 3.2) * -150 - 10 * ffr))
	end

	
	mdl:ManipulateBonePosition(1, Vector(0, -6 * ffr, -14 * ffr))

	for i=8, 12 do
		mdl:ManipulateBoneScale(i, Vector())
	end

	mdl:DrawModel()

	cam.End3D()

	mdl:SetNoDraw(true)
end)