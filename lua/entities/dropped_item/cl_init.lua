include("shared.lua")

Inventory.DroppedItemPool = Inventory.DroppedItemPool or {}

ENT.GlowRadius = 72 -- only for renderbounds
ENT.BeamHeight = 96

function ENT:CLInit()
	self.Wisps = {}
	self.Random = math.random()
	self:GenWisp()

	local mins = Vector(-self.GlowRadius, -self.GlowRadius, -self.BeamHeight)
	self:SetRenderBounds(mins, -mins, Vector(4, 4, 4))
end

local cab = Material("trails/physbeam") -- Material("models/wireframe") -- Material("trails/laser")

-- refract_ring
-- materials/particle/particle_ring_wave
local ring = Material("particle/particle_ring_wave_additive")
ring:SetInt("$vertexalpha", 1)

local glows = {
	"sprites/light_glow02",
	"sprites/glow01",
	"sprites/light_glow01",
}

local additives = {
	"sprites/laser"
}

for k,v in pairs(glows) do
	glows[k] = CreateMaterial("itemdrop_glow" .. k, "UnlitGeneric", {
		["$additive"] = "1",
		["$basetexture"] = v,
		["$translucent"] = "1",
		["$vertexcolor"] = "1",
		["$vertexalpha"] = "1"
	})
end

for k,v in pairs(additives) do
	additives[k] = CreateMaterial("itemdrop_add" .. k, "UnlitGeneric", {
		["$additive"] = "1",
		["$basetexture"] = v,
		["$translucent"] = "1",
		["$vertexcolor"] = "1",
		["$vertexalpha"] = "1",
	})
end

local additives = {
	Material("models/wireframe"),
	Material("sprites/light_glow02_add")
}

local temp = Vector()
local col = Color(255, 255, 255)

function ENT:DrawBeamAnimation(pos, ubFr)
	local fr = math.min(1, ubFr)
	local dorig = self:GetDropOrigin()

	local eFr = fr
	local brkPoint = 0.5
	local pow = 5
	local height = self.BeamHeight

	if eFr > brkPoint then
		eFr = (brkPoint) + (((eFr - brkPoint) / (1 - brkPoint)) ^ pow) * (1 - brkPoint)
	end

	local headPos = LerpVector(eFr, dorig, pos)
	headPos.z = headPos.z + height * math.sin(fr * math.pi * 1)

	local trailLen = 0.4
	local trailSegs = 64
	local texTile = 16

	local minLen = math.ceil(math.min(trailSegs,
		ubFr * trailSegs / trailLen,
		((1 + trailLen) - ubFr) * trailSegs / trailLen
	)) + 1

	local px, py, pz = pos:Unpack()
	local ox, oy, oz = dorig:Unpack()
	local curStep = 0
	local step = trailLen / trailSegs
	local start = math.max(ubFr - (ubFr > 1 and (trailLen - (ubFr - 1) * 0.4) or trailLen), 0)

	render.StartBeam(minLen)

	-- calculate tail
	for i=start, fr, step do
		curStep = i - start

		local eFr = i
		if eFr > brkPoint then
			eFr = (brkPoint) + (((eFr - brkPoint) / (1 - brkPoint)) ^ pow) * (1 - brkPoint)
		end

		local zAdd = height * math.sin(eFr * math.pi * 1)
		
		temp:SetUnpacked(
			Lerp(i, ox, px),
			Lerp(i, oy, py),
			Lerp(i, oz, pz) + zAdd
		)

		render.AddBeam(temp, math.min(1, curStep / trailLen * 1) * 16,
			(i - fr) * texTile, color_white)
	end

	local finalTex = 0
	render.SetMaterial(cab)
	render.AddBeam(headPos, math.min(1, fr / trailLen) * 16, finalTex, color_white)

	render.EndBeam()
end

local wispCol = color_white:Copy()

function ENT:GenWisp()
	local wantWisps = math.random(3, 8)
	local wisps = self.Wisps

	for i=#wisps, wantWisps - 1 do
		local randPos = VectorRand(-12, 12)
		randPos.z = 0
		wisps[#wisps + 1] = {
			CurTime() + math.random() * 1,
			randPos,
			2.4 + math.random() * 5,
			math.random(#glows),
			math.random(-8, 16)
		}
	end
end

function ENT:DrawWisps(pos)
	local wisps = self.Wisps

	local itm = self:GetItem()
	local rar = itm and itm:GetRarity()
	local rCol = rar and rar:GetColor() or Colors.Red
	wispCol:Set(rCol)
	wispCol:MulHSV(1, 0.5, 1.3)

	local ct = CurTime()

	local fadeInFr = 0.15
	local fadeOutFr = 0.8

	for i=#wisps, 1, -1 do
		local v = wisps[i]
		local st = v[1] 			-- start time
		if st > ct then continue end

		local sPos = v[2] 			-- randomized pos around the item
		local len = v[3] 			-- time to last
		local glowTyp = v[4] 		-- random number for glows tbl
		local off = v[5]

		local ubFr = (ct - st) / len
		local fr = ubFr

		if fr < fadeInFr then
			fr = fr / fadeInFr -- 0 - 0.15 = fade to 1
		elseif fr < fadeOutFr then
			fr = 1 -- 0.15 - 0.8 = 1
		else
			fr = math.Remap(fr, fadeOutFr, 1, 1, 0)
		end

		if fr < 0 then
			table.remove(wisps, i)
			self:GenWisp()
			continue
		end

		wispCol.a = fr * 150 + math.random(0, 35)

		temp:Set(pos)
		temp:Add(sPos)
		temp[3] = temp[3] - off + ubFr * 12

		render.SetMaterial(glows[glowTyp])
		render.DrawSprite(temp, 8, 8, wispCol)
	end
end

local rarityCol = Color(255, 255, 255)
local addUp = Vector(0, 0, 1)
local cols = {
	Color(200, 200, 200)
}

function ENT:DrawGlow(pos, fr)
	if fr == 0 then return end

	local itm = self:GetItem()
	local rar = itm and itm:GetRarity()
	local rCol = rar and rar:GetColor() or Colors.Red
	cols[2] = rCol

	fr = Ease(fr, 0.7)
	local gfr = 3 - fr * 2

	-- beam up
	for i=1, 2 do
		local col = cols[i]
		render.SetMaterial(additives[2])
		temp:Set(pos)

		local z = temp[3]
		z = z - 4

		temp[3] = z

		local sz = i ^ 2 * 2 + (1 - fr) * 128
		render.StartBeam(6)
			render.AddBeam(temp, sz, 0, col)
			z = z + 4 * fr
			temp[3] = z
			render.AddBeam(temp, sz, 0.4, col)
			render.AddBeam(temp, sz, 0.5, col)
			z = z + 36 * fr
			temp[3] = z
			render.AddBeam(temp, sz, 0.5, col)
			z = z + 12 * fr
			temp[3] = z
			render.AddBeam(temp, sz, 0.6, col)
			z = z + 32 * fr
			temp[3] = z
			render.AddBeam(temp, sz, 1, col)
		render.EndBeam()
	end

	if self:GetItem() and fr >= 1 then
		local b = self:GetItem():GetBase()
		if b then
			temp:Set(pos)
			temp[3] = temp[3] + math.sin((CurTime() + self.Random * math.pi * 2) * 2.4) * 1.4
			b:Paint3D(temp, self:GetAngles(), self:GetItem())
		end
	end

	rarityCol:Set(rCol)

	local flashTime = (self.NextFlashTime or 0)
	local flashFr = CurTime() - flashTime > 0 and 1 - (CurTime() - flashTime) / 0.4 or 0

	if flashFr < 0 then
		self.NextFlashTime = CurTime() + 0.4 + math.random() * 1.1
		self.NextFlashOffset = VectorRand(-3, 3)
	end

	rarityCol.a = fr * 255

	-- glow
	local dist = EyePos():Distance(pos) - 96

	local alpha = Lerp(dist / 192, 20, 255)
	local prevA = rarityCol.a

	rarityCol.a = alpha
	local sz = 48 + math.sin(CurTime() * 2) * 4
	render.SetMaterial(glows[1])
	render.DrawSprite(pos, gfr * sz, gfr * sz, rarityCol)

	sz = 60 + math.sin(CurTime() * 1.2) * 12
	render.SetMaterial(glows[2])
	render.DrawSprite(pos, gfr * sz, gfr * sz, rarityCol)

	rarityCol.a = prevA

	if flashFr > 0 then
		sz = 56 * flashFr
		render.SetMaterial(glows[3])
		render.DrawSprite(pos + (self.NextFlashOffset or vector_origin), gfr * sz, gfr * sz, rarityCol)
	end
end

function ENT:Draw()
	--[[
	self:DrawModel()
	self:SetColor(Color(255, 255, 255, 100))
	]]

	local zOff = Vector(0, 0, self:OBBMins().z / 2)
	local pos = self:GetPos() - zOff

	local fr = CurTime() - self:GetCreatedTime()
	local ubFr = fr / self.TimeToAnimate -- unbound frac
	self:DrawBeamAnimation(pos, ubFr)

	local ringFr = math.max(0, (ubFr - 1) * 1.5)

	if ringFr > 0 and ringFr <= 1 then
		render.SetMaterial(ring)
		col.a = (1 - ringFr) * 255
		ringFr = Ease(ringFr, 0.35)
		render.DrawSprite(pos, 8 + ringFr * 24, 8 + ringFr * 24, col)
	end

	ringFr = math.min(ringFr, 1)
	self:DrawGlow(pos, ringFr)


	self:DrawWisps(pos)
end

function ENT:GetItem()
	local id = self:GetNWItemID()
	return Inventory.DroppedItemPool[id]
end

net.Receive("dropped_item_itm", function()
	local itm = Inventory.Networking.ReadItem(uid_sz, iid_sz)
	Inventory.DroppedItemPool[itm:GetUID()] = itm
end)