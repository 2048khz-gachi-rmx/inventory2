include("shared.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

function ENT:PhysicsCollide(dat, collider)
	if dat.HitEntity ~= game.GetWorld() then return end

	local nang = dat.HitNormal:Angle()
	nang:RotateAroundAxis(nang:Right(), 90)
	self:SetAngles(nang)
	dat.PhysObject:EnableMotion(false)
	self:SetLandTime(CurTime())
	self:SetOwner(NULL)
	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	--self:SetPos()
end

SonarOwners = SonarOwners or {}
local sonarOwners = SonarOwners

ActiveSonarTrack = ActiveSonarTrack or {}
local active_track = ActiveSonarTrack

function ENT:Initialize()
	self:SetModel(self.Model)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)

	self:PhysWake()
	self:Activate()
	self:SetModelScale(0.5, 0)

	local p = self:GetPhysicsObject()
	p:SetMass(800)
	p:SetDamping(0, 2)
	p:SetDragCoefficient(0)

	self:AddEFlags( EFL_FORCE_CHECK_TRANSMIT )
	self.hp = 50

	self._tracked = {}
	self._lastTrack = 0

	util.SpriteTrail(self, 0, Color(250, 150, 90, 210), true,
		8, 2, 0.7, 1, "trails/plasma")
end

function ENT:OnTakeDamage(dmg)
	self.hp = self.hp - dmg:GetDamage()
	if self.hp <= 0 then
		self:Remove()
		local vPoint = self:GetPos()
		local effectdata = EffectData()
		effectdata:SetOrigin(vPoint)
		util.Effect("Explosion", effectdata)
	else
		local vPoint = self:GetPos()
		local effectdata = EffectData()
		effectdata:SetOrigin(vPoint)
		util.Effect(a or "ManhackSparks", effectdata)
		self:EmitSound("DoSpark")
	end
end

function ENT:SetReleaser(ply) -- ?? nice name
	sonarOwners[ply] = sonarOwners[ply] or {}
	table.insert(sonarOwners[ply], self)

	local pin = ply:GetPInfo()
	local fac = pin and pin:GetFaction()

	self._rel = ply
	self._fac = fac

	if fac then
		fac._sonars = fac._sonars or {}
		table.insert(fac._sonars, self)
	end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

local updateIntervalTicks = 8

local function writeTrack(where, who)
	where[who] = who:UserID()
end

local function doTrack(ply, forply, uid)
	-- ply:AddEFlags(EFL_IN_SKYBOX)
	AddOriginToPVS(ply:GetPos())
	local priv = forply:GetPInfo():GetPrivateNW()
	priv:Set("Trk_" .. uid, true)
end

local function doUntrack(ply, forply, force)
	local priv = forply:GetPInfo():GetPrivateNW()
	local key = "Trk_" .. (active_track[ply] or ply:UserID())

	if priv:Get(key) then
		priv:Set(key, nil)
	end

	forply._track[ply] = nil
end

local function isTracked(ply)
	return active_track[ply]
end

function ENT:OnRemove()
	table.RemoveByValue(sonarOwners[self._rel], self)
	if self._fac then
		table.RemoveByValue(self._fac._sonars, self)
	end

	for k,v in ipairs(self._tracked) do
		print("have tracked", v)
		if v:IsValid() then
			doUntrack(v, self._rel, true)
		end
	end
end

function ENT:CalculatePVS(trkTbl)
	if self:GetLandTime() == 0 then return end

	local tick = engine.TickCount()

	if tick - self._lastTrack < updateIntervalTicks then
		-- not time to rescan; just track who's needed
		for k,v in ipairs(self._tracked) do
			if v:IsValid() then
				writeTrack(trkTbl, v)
			end
		end
		return
	end

	self._lastTrack = tick

	local mePos = self:GetPos()
	local meRad = (self:GetScanRadius() + 32) ^ 2

	local t = self._tracked
	table.Empty(t)

	for k,v in ipairs(player.GetConstAll()) do
		if isTracked(v) then continue end

		local pos = v:GetPos()

		if mePos:DistToSqr(pos) > meRad then
			continue -- too far
		end

		-- all good; start tracking
		t[#t + 1] = v
		writeTrack(trkTbl, v)
	end
end

local function untrackAll(ply, trkTbl)
	for k,v in pairs(trkTbl) do
		doUntrack(k, ply)
	end
end

hook.Add("SetupPlayerVisibility", "Sonar", function(ply)
	local pin = ply:GetPInfo()
	local fac = pin:GetFaction()

	ply._track = ply._track or {}

	if fac then
		local srs = fac._sonars

		untrackAll(ply, ply._track) -- everyone the player was tracking gets reset

		if not srs or #srs == 0 then
			return
		end

		if fac._trackFilled ~= engine.TickCount() then
			for k,v in ipairs(srs) do
				v:CalculatePVS(ply._track) -- then refilled
			end

			fac._trackFilled = engine.TickCount()
		end

		for who, uid in pairs(ply._track) do
			doTrack(who, ply, uid) -- then marked as tracked (and networked)
		end

	else
		local srs = sonarOwners[ply]

		untrackAll(ply, ply._track)

		if not srs or #srs == 0 then
			return
		end

		for k,v in ipairs(srs) do
			v:CalculatePVS(ply._track)
		end

		for who, uid in pairs(ply._track) do
			doTrack(who, ply, uid)
		end
	end
end)