include("shared.lua")

function ENT:CLInit()

end

local cab = Material("trails/physbeam") -- Material("models/wireframe") -- Material("trails/laser")

-- refract_ring
-- materials/particle/particle_ring_wave
local ring = Material("particle/particle_ring_wave_additive")
ring:SetInt("$vertexalpha", 1)

local temp = Vector()
local temp2 = Vector()
local col = Color(255, 255, 255)

function ENT:Draw()
	--self:DrawModel()
	self:SetColor(Color(255, 255, 255, 100))
	local fr = CurTime() - self:GetCreationTime()
	local ubFr = fr / self.TimeToAnimate
	fr = math.min(1, fr / self.TimeToAnimate)

	local dorig = self:GetDropOrigin()
	local pos = self:GetPos()

	local eFr = Ease(fr, 1)
	local vec = LerpVector(eFr, dorig, pos)
	local zAdd = 80 * math.sin(fr * math.pi)
	vec.z = vec.z + zAdd

	local trailLen = 0.4
	local trailSegs = 64
	local texTile = 16

	local minLen = math.ceil(math.min(trailSegs,
		ubFr * trailSegs / trailLen,
		((1 + trailLen) - ubFr) * trailSegs / trailLen
	)) + 1

	render.StartBeam(minLen)

	local px, py, pz = pos:Unpack()
	local ox, oy, oz = dorig:Unpack()
	local curStep = 0
	local step = trailLen / trailSegs
	local start = math.max(ubFr - trailLen, 0)

	--render.SetColorMaterial()
	local dist = pos:Distance(dorig)

	for i=start, fr, step do
		curStep = i - start

		local zAdd = 80 * math.sin(i * math.pi)
		local eFr = i
		temp:SetUnpacked(
			Lerp(eFr, ox, px),
			Lerp(eFr, oy, py),
			Lerp(eFr, oz, pz) + zAdd
		)

		render.AddBeam(temp, math.min(1, curStep / trailLen * 1) * 16,
			(i - fr) * texTile, color_white)

		render.SetColorMaterial()
		--render.DrawSphere(temp, 1, 8, 8, color_white)
	end

	local finalTex = 0
	render.SetMaterial(cab)
	render.AddBeam(vec, math.min(1, fr / trailLen) * 16, finalTex, color_white)

	render.EndBeam()

	render.SetColorMaterial()

	local ringFr = math.max(0, (ubFr - 1) * 2)

	if ringFr > 0 and ringFr <= 1 then
		render.SetMaterial(ring)
		col.a = (1 - ringFr) * 255
		ringFr = Ease(ringFr, 0.25)
		render.DrawSprite(pos, ringFr * 48, ringFr * 48, col)
	end

	--render.DrawSphere(vec, 2, 8, 8, Colors.Sky)
end