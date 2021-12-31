include("shared.lua")

local mat = Material("effects/tvscreen_noise003a")
mat:SetInt("$flags", bit.bor(mat:GetInt("$flags"), 16, 32, 128, 2097152)) -- vertexalpha

local beamMat = Material("trails/plasma")

local ring = Material("particle/particle_ring_wave_additive")
ring:SetInt("$vertexalpha", 1)

--[[local mat = --Material("models/weapons/v_slam/new light1")
mat:SetInt("$vertexalpha", 1)
mat:SetInt("$translucent", 1)
mat:SetFloat("$alpha", 1)
mat:SetVector("$color", Vector(0.4, 0.3, 0.2))]]
--[[CreateMaterial("sonar_sphere", "VertexLitGeneric", {
	["$basetexture"] = "models/props_combine/com_shield001a",
	["$vertexalpha"] = "1",
})]]

local sphereCol = Vector(0.75, 0.7, 0)
local beamCol = Color(250, 120, 60, 160)

local tempvec = Vector()
local beampos = Vector()
local circVec = Vector()

local trail = {}
local trailLen = 32
local trailFall = 3

for i=1, trailLen do
	trail[i] = Vector()
end

local temp = {}

local rt, rtMat

local function setupRt()
	if rt then return end

	rt, rtMat = draw.GetRTMat("SonarScanline3", 16, 1024, "UnlitGeneric")

	rtMat:SetInt("$flags", bit.bor(rtMat:GetInt("$flags"), 128) )
	-- ffs setting $additive doesnt work but this flag shit does?
	-- thanks ~~obama~~ garry

end

local mins, maxs = Vector(), Vector()

function ENT:Initialize()
	setupRt()

	mat:SetVector("$color", sphereCol)

	local r = self:GetScanRadius()
	self:SetRenderBounds(
		Vector(-r, -r, -r),
		Vector(r, r, r), Vector(4, 4, 4))
end

if LibItUp then -- autorefresh?
	setupRt()
end

local function precalc(origin, plyPos, rad)
	local zpos = math.Clamp(plyPos[3], origin[3] - rad * 0.75, origin[3] + rad * 0.75)
	local zdiff = zpos - origin[3]

	temp[1] = zpos
	temp[2] = zdiff
	temp[3] = math.sqrt(rad^2 - zdiff^2)
end

local function calcPoint(origin, plyPos, rad, ang, out)
	out:Set(origin)

	local zpos = temp[1]
	local left = temp[3]

	circVec.x = math.sin(ang) * left
	circVec.y = math.cos(ang) * left

	out:Add(circVec)
	out.z = zpos
end

local lineCol = Color(230, 150, 70)

local function drawScan(w, h, rt, fr)
	lineCol.a = 40 + math.random() * 85

	local scanSz = 8

	surface.SetDrawColor(lineCol)
	surface.SetMaterial(MoarPanelsMats.gu)
	surface.DrawTexturedRect(0, -4 + (h + 12) * fr, w, scanSz)

	surface.SetMaterial(MoarPanelsMats.gd)
	surface.DrawTexturedRect(0, -8 + (h + 12) * fr, w, scanSz)
end

function ENT:Draw()
	self:DrawModel()

	if self:GetLandTime() == 0 then
		return
	end

	local ex = 1.5
	local passed = CurTime() - self:GetLandTime()
	local fr = math.ease.OutElastic( math.min(1, passed / ex) , 0.4 )

	--render.OverrideDepthEnable(true, true)
	local lp = LocalPlayer()
	local lpos = lp:GetPos()
	lpos:Add(lp:OBBCenter() * 0.5)
	--lpos[3] = lpos[3] + math.sin(CurTime() * 2) * 128
	local mypos = self:GetPos()

	local t = CurTime() * 5
	local rad = self:GetScanRadius()

	precalc(mypos, lpos, rad)
	calcPoint(mypos, lpos, rad, t * 2, beampos)

	render.SetMaterial(beamMat)
	render.DrawBeam(mypos, beampos, 8, math.random(), math.random() + 2, beamCol)

	local col = Color(0, 0, 0, 1)

	for i=1, trailLen do
		calcPoint(mypos, lpos, rad, t * 2 - i * (trailFall / trailLen), trail[i])
	end

	render.StartBeam(trailLen + 1)
	render.AddBeam(beampos, 32, 0, color_white)
	render.SetMaterial(beamMat)
	for i=1, trailLen do
		render.AddBeam(trail[i], 32 - i * 2, 0, beamCol)
	end
	render.EndBeam()

	render.SetMaterial(ring)
	tempvec:Set(mypos)

	local scanFr = ((CurTime() * 1.2) % 2 - 1)

	if scanFr > 0 then
		draw.RenderOntoRT(rt, 16, 1024, drawScan, scanFr)

		cam.IgnoreZ(true)
		render.SetMaterial(rtMat)
		render.DrawSphere(self:GetPos(), fr * rad, 64, 64, color_white)
		cam.IgnoreZ(false)
	end

	draw.BeginMask()
	render.SetStencilCompareFunction(STENCIL_NOTEQUAL)
	render.SetStencilPassOperation(STENCIL_REPLACE) -- stencil dark magic

	render.SetMaterial(mat)

	render.DrawSphere(self:GetPos(), fr * rad, 32, 32, col)
	render.DrawSphere(self:GetPos(), -fr * rad, 32, 32, col)

	draw.FinishMask()
end

SonarTrack = SonarTrack or {}

local t = {}

hook.Add("PostDrawTranslucentRenderables", "Sonar", function(b, s)
	if b or s then return end

	for ply, _ in pairs(SonarTrack) do
		if not ply:Alive() then
			local rag = ply:GetRagdollEntity()
			if rag:IsValid() then
				t[1] = rag
				halo.Add(t, Colors.Red, 2, 2, 2, true, true)
			end
		else
			t[1] = ply
			halo.Add(t, Colors.Yellowish, 2, 2, 2, true, true)
		end
	end
end)

hook.Add("NetworkableChanged", "SonarTrack", function(nw, changes)
	if not nw.IsPrivateNW then print("meh not priv") return end

	table.Empty(SonarTrack)

	print("average nwable enjoyer")

	for k,v in pairs(nw:GetNetworked()) do
		if not k:match("^Trk_") then  continue end

		local uid = tonumber(k:match("^Trk_(%d+)"))
		local ply = Player(uid)
		if ply == LocalPlayer() then continue end
		SonarTrack[ply] = true
	end
end)