local FX = {}

function EFFECT:Init( data )
	self.origin = data:GetOrigin()
	self.origin[3] = self.origin[3] + 8

	self.CT = CurTime()
	self.Radius = data:GetRadius() or 64
	self.Length = data:GetMagnitude() or 5

	self.DisappearOvertime = 1.5
	self.DisappearLength = 2

	self.SnuffOutTime = 1

	self.FT = 0
	self.InitFreq = 1 / 90
	self.Freq = self.InitFreq

	FX[#FX + 1] = self
end

function EFFECT:GetExistTime()
	return CurTime() - self.CT
end

function EFFECT:Think()
	local left = self.Length - (CurTime() - self.CT)
	local sn = self.SnuffOutTime

	if left < sn then
		self.Freq = Lerp((sn - left) / sn, self.InitFreq, 1 / 10)
		if left < 0 then
			self.Freq = math.huge
		end
	end

	local needExist = (left + self.DisappearOvertime) > 0
	if not needExist then
		table.RemoveByValue(FX, self)
	end

	return needExist
end

local vel = Vector()
local cpy = Vector()
local cab = Material("effects/bluelaser1")

function EFFECT:Render() end

function EFFECT:DrawBeam()
	local segs = 64
	local t = self:GetExistTime()
	local fr = Ease(math.min(1, t / 1.8), 0.1)

	local tLeft = (self.Length + self.DisappearOvertime) - t

	local dl = self.DisappearLength
	if tLeft < dl then
		fr = Ease(math.max(0, tLeft / dl), 0.3)
	end

	render.StartBeam(segs + 1)
	local ox, oy, oz = self.origin:Unpack()
	cpy.z = oz

	local texU = CurTime() % 3 / 3

	for i=0, segs do
		local ang = math.rad(360 / segs * i)
		local x, y = math.cos(ang), math.sin(ang)
		cpy[1] = ox + x * self.Radius * fr
		cpy[2] = oy + y * self.Radius * fr

		render.AddBeam(cpy, 4, texU + 16 / segs * i, color_white)
	end

	render.SetMaterial(cab)
	render.EndBeam()
end

function EFFECT:CustomRender(ft)
	local vOffset = cpy

	local mul = 0.15
	local lifeTime = 0.5

	local total_ft = self.FT + ft
	local freq = self.Freq

	local amt = math.floor(total_ft / freq)
	self.FT = total_ft % freq

	self:DrawBeam()

	cpy:Set(self.origin)
	if amt < 1 or amt > 100 then return end

	local em = ParticleEmitter( vOffset, false )
		for i=1, amt do
			local dir = math.rad( math.random() * 360 )
			local timeLive = self.Length * lifeTime
			local speed = math.random(self.Radius * 0.8, self.Radius) / timeLive

			vel:SetUnpacked(
				math.cos(dir) * speed,
				math.sin(dir) * speed,
				math.random(2, 4)
			)

			vel:Mul(mul)

			vOffset:Sub(vel)
			vOffset.z = vOffset.z + vel[3] * timeLive
			local part = em:Add("particle/particle_smokegrenade", vOffset)
			vOffset:Add(vel)

			if part then
				vel:Div(mul)

				part:SetCollide(true)
				part:SetVelocity( vel )
				part:SetColor( 250, 252, 50 )
				part:SetLifeTime( 0 )
				part:SetBounce(2)
				part:SetDieTime( self.Length * lifeTime )

				part:SetStartAlpha( 180 )
				part:SetEndAlpha( 0 )

				part:SetStartSize( 16 )
				part:SetEndSize( 64 )

				part:SetStartLength( 16 )
				part:SetEndLength( 64 )
			end
		end
	em:Finish()
end

hook.Add("PreDrawEffects", "DrawMendGas", function()
	if #FX == 0 then return end

	local ft = FrameTime()

	for k,v in ipairs(FX) do
		v:CustomRender(ft)
	end
end)