--
local numCol, notNumCol, textCol = unpack(Inventory.Modifiers.DescColors)

local activeCol = Color(255, 255, 255)
local inactiveCol = Offhand.InactiveColor
local col = inactiveCol:Copy()

local smokes = {}

for i=1, 16 do
	smokes[i] = Material(("particle/smokesprites_00%02d"):format(i))
end

local handle = BSHADOWS.GenerateCache("MendGas", 128, 128)
handle:SetGenerator(function(self, w, h)
	draw.SimpleText("GAS", "OSB86", w / 2, h / 2, color_white, 1, 1)
end)

handle.cached = false

local el = Inventory.Modifiers.Get("MendGas")

local anim = Animatable("MendGas")
anim.Frac = 0

local particles = {}

local function makePart(t)
	return {
		t + Lerp(math.random(), 0.4, 0.9), 	-- appear_time
		t + Lerp(math.random(), 4, 7),		-- death_time
		Lerp(math.random(), 0.4, 2),		-- fadein_dur

		{math.Sign(math.random() - 0.5) * math.random(), math.Sign(math.random() - 0.5) * math.random()},		 -- x, y
		Lerp(math.random(), 2, 6),   -- velocity up
		Lerp(math.random(), 0.8, 1.2), -- size

		smokes[math.random(#smokes)], -- mat
		Lerp(math.random(), 0.2, 0.5) -- rotation speed
	}
end

local function sorter(a, b)
	return a[2] > b[2]
end

local MAX_ACTIVE = 32
timer.Create("mendgas_parts", 0.25, 0, function()
	local st = SysTime()
	local disap = 0

	for i=#particles, 1, -1 do
		local v = particles[i]
		local die = v[2]
		if die < st then
			particles[i] = nil
		elseif die - math.max(0.3, v[3]) * 2 < st then
			-- disappearing: consider dead but dont delete
			disap = disap + 1
		else
			break
		end
	end

	local added = false
	for i=1, MAX_ACTIVE - #particles + disap do
		added = true
		particles[#particles + 1] = makePart(st)
	end

	if added then
		table.sort(particles, sorter)
	end
end)

local colAc = Color(240, 220, 105)
local colInac = Color(150, 140, 15)
local curCol = colAc:Copy()

el --:SetIcon(Icon("https://i.imgur.com/OjieIw3.png", "beacon.png"):SetSize(64, 64))
:SetPaint(function(base, fr, x, y, sz)

	local mod = base:GetModFromPlayer(LocalPlayer())
	local allcd = mod and eval(base:GetCooldown(), base, mod, LocalPlayer()) or 1
	local cdFrac = mod and 1 - (math.max(0, (mod:GetCooldown() or 0) - CurTime()) / allcd) or 1

	local frTo = mod and 1 or 0
	frTo = frTo * (cdFrac == 1 and 1 or 0.2)

	fr:To("SonarAcFr", frTo, 0.3, 0, 0.3)

	local acf = fr.SonarAcFr or 0
	draw.LerpColor(acf, col, activeCol, inactiveCol)

	local fsz = sz * cdFrac
	local mx = math.floor(x + sz / 2 - fsz / 2)

	anim.size = anim.size or 0.5

	local szMult = math.max( Ease(Lerp(cdFrac, 0.5, 1), 4), anim.size )
	local colFr = math.max(0, math.Remap(szMult, 0.8, 1, 0, 1))
	curCol:Lerp(colFr, colInac, colAc)

	if cdFrac == 1 and anim.size < 1 then
		anim:RemoveLerp("size")
		anim.size = 1
	end

	local st = SysTime()
	for k,v in ipairs(particles) do
		local maxA = 150
		local a = math.min(maxA,
			math.Remap(st, v[1], v[1] + v[3], 0, maxA),
			math.Remap(st, v[2] - math.max(0.3, v[3]) * 2, v[2], maxA, 0)
		)
		if a < 0 then continue end

		local pos, vel, ssz, mat, rotspeed = unpack(v, 4)
		local sx, sy = pos[1], pos[2]
		local sinceStart = st - v[1]

		surface.SetMaterial(mat)

		curCol.a = a

		surface.SetDrawColor(curCol:Unpack())
		surface.DrawTexturedRectRotated(
			x + sz / 2 + sx * sz * szMult / 2,
			y + sz / 2 + sz * sy * szMult / 2 - sinceStart * vel,
			ssz * sz * szMult,
			ssz * sz * szMult,
			sinceStart * 60 * rotspeed
		)
	end
end)

:SetOnActivate(function(base, me, mod)
	local pr = base:RequestAction(mod)

	me:EmitSound("arccw_go/decoy/grenade_throw.wav", 50, math.random(90, 110), 0.7)

	pr:Then(function()
		anim:To("size", 0.5, 0.9, 0, 0.15)

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

	desc:AddText("Deploy mending gas that heals everyone within its' radius for ")

	for i=1, self:GetMaxTier() do
		local tx2 = desc:AddText(tostring(self:GetTierStrength(i)))
		tx2.color = i == tier and numCol or notNumCol

		if i ~= self:GetMaxTier() then
			local sep = desc:AddText("/")
			sep.color = notNumCol
		end
	end

	desc:AddText(" HP.")
end

local mat = Material("grp/mendgas/mend")
mat:SetVector("$color2", Vector(0, 1, 1))
mat:SetVector("$color", Vector(1, 1, 0.4))
mat:SetFloat("$pulsing_strength", 0)
mat:SetFloat("$pulsing_speed_mul", 0)

--[[hdl.DownloadFile("http://vaati.net/Gachi/shared/mend_overlay.vtf",
"mend_overlay.vtf", function(fn)

	mat:SetTexture("$basetexture", "../" .. fn:gsub("%.vtf$", ""))
end)]]

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