--
local numCol, notNumCol, textCol = unpack(Inventory.Modifiers.DescColors)

local activeCol = Color(255, 255, 255)
local inactiveCol = Offhand.InactiveColor
local col = inactiveCol:Copy()

local handle = BSHADOWS.GenerateCache("MendGas", 128, 128)
handle:SetGenerator(function(self, w, h)
	Icon("https://i.imgur.com/OjieIw3.png", "beacon.png")
		:SetSize(w, h)
		:Paint(0, 0, w, h)
end)

handle.cached = false

local el = Inventory.Modifiers.Get("MendGas")

local anim = Animatable("MendGas")
anim.Frac = 0

el --:SetIcon(Icon("https://i.imgur.com/OjieIw3.png", "beacon.png"):SetSize(64, 64))
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

	--local icc = base:GetIconCopy()
	--icc:SetColor(col)

	handle:Paint(x, y, sz, sz)

	local fsz = sz * cdFrac
	local mx = math.floor(x + sz / 2 - fsz / 2)

	White()
	draw.BeginMask()
	--draw.SetMaskDraw(true)
		surface.DrawRect(mx, y, math.ceil(fsz), sz)
	draw.DrawOp()
		--icc:Paint(x, y, sz, sz)
	draw.FinishMask()

	
	-- print(col, acf, mod)
end)

:SetOnActivate(function(base, me, mod)
	local pr = base:RequestAction(mod)

	me:EmitSound("arccw_go/decoy/grenade_throw.wav", 50, math.random(90, 110), 0.7)

	pr:Then(function()
		-- ?

		me:LiveTimer("MendGas_Pull", 0.5, function()
			me:ViewPunch(Angle(-2, 0.3, -1))
		end)

		me:LiveTimer("MendGas_RevPunch", 0.75, function()
			me:ViewPunch(Angle(1, 1, 1))
			me:SetViewPunchAngles(Angle(1, -1, 1))
		end)
	end, function()
		-- failed for some reason
		me:EmitSound("buttons/button11.wav", 50)
	end)
end)

el:SetDescription("Deploy a gas cloud that heals anyone standing in it.")

function el:GenerateMarkup(it, mup, tier)
	local mod = mup:AddPiece()
	mod:SetAlignment(1)
	mod.Font = "OS20"

	local tx = mod:AddText("Mend-gas " .. string.ToRoman(tier))
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

local mat = Material("overwatch/overlays/lowhealth")
mat:SetVector("$color2", Vector(0, 1, 1))
mat:SetVector("$color", Vector(1, 1, 0.4))
mat:SetFloat("$pulsing_strength", 0)
mat:SetFloat("$pulsing_speed_mul", 0)

hdl.DownloadFile("http://vaati.net/Gachi/shared/mend_overlay.vtf",
"mend_overlay.vtf", function(fn)

	mat:SetTexture("$basetexture", "../" .. fn:gsub("%.vtf$", ""))
end)

hook.Add("DrawOverlay", "MendOverlay", function()
	local me = CachedLocalPlayer()

	if not me:GetPrivateNW():Get("Mending") then
		anim:To("MendFrac", 0, 1.8, 0, 2.7)
	else
		anim:To("MendFrac", 1, 0.5, 0, 0.3)
	end

	local fr = anim.MendFrac or 0
	if fr == 0 then return end

	local w, h = ScrW(), ScrH()
	local x, y = -w * (1 - fr) * 0.5, -h * (1 - fr) * 0.5
	w = w * (1 + (1 - fr) * 1)
	h = h * (1 + (1 - fr) * 1)

	surface.SetDrawColor(255, 255, 255, 255)
	surface.SetMaterial(mat)

	surface.DrawTexturedRect(x, y, w, h)
end)