include("shared.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

util.AddNetworkString("dropped_item_itm")

local sfx = {
	common = 4,
	uncommon = 4,
	rare = 3
}

function ENT:SVInit()
	if not self.Item and SERVER then
		self:Remove()
		errorf("missing item")
		return
	end

	self:SetCreatedTime(CurTime())
	self:SetModel(self.Model)
	self:SetSkin(self.Skin)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:GetPhysicsObject():EnableMotion(false)
	self:SetRenderMode(RENDERMODE_TRANSALPHA)

	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

	self:SetUseType(SIMPLE_USE)

	--self:PhysWake()
	self:Activate()
	self:Timer("AutoRemoval", Inventory.DropCleanupTime, 1, function()
		self:Remove()
	end)
end

local dftDropDist = 48
local dftDropHeight = 64
local traceSegs = 32 -- tracing accuracy (this many hull traces fired to calculate collision)

--[[
params = {
	DropOrigin = self:GetPos() + self:OBBCenter()
	DropDistance = 48,
	DropHeight = 64,
	DropDirection = 0-360
}
]]
local dropBounds = Vector(8, 8, 8)

function ENT:PickDropSpot(ignore, params)
	local ignoreTable = player.GetAll()
	table.insert(ignoreTable, drop)
	if istable(ignore) then table.Add(ignoreTable, ignore) end

	local dropDist, dropHeight, dropDir, sPos

	if not params then
		dropDist, dropHeight, dropDir = dftDropDist, dftDropHeight, math.random() * 360
		sPos = self:GetPos() + self:OBBCenter()
	else
		dropDist = params.DropDistance or dftDropDist
		dropHeight = params.DropHeight or dftDropHeight
		dropDir = params.DropDirection or math.random() * 360
		sPos = params.DropOrigin or self:GetPos() + self:OBBCenter()
	end

	local lastPos = sPos
	local hitPos
	local temp = Vector()

	local off = Vector(
			math.cos(math.rad(dropDir)) * dropDist,
			math.sin(math.rad(dropDir)) * dropDist,
			0)

	local out = {}
	local hullTbl = {
		mins = -dropBounds,
		maxs = dropBounds,

		start = lastPos,
		--endpos = newPos,
		filter = ignoreTable,

		output = out,
	}

	for i=0, 1, 1 / traceSegs do
		local tr = out

		local newPos = LerpInto(i, sPos, sPos + off, temp)
		newPos[3] = newPos[3] + math.sin(i * math.pi) * dropHeight

		hullTbl.start = lastPos
		hullTbl.endpos = newPos

		local tr = util.TraceHull(hullTbl)

		if tr.Hit then
			hitPos = tr.HitPos
			break
		end

		lastPos = newPos
	end

	-- trace downwards till ground
	hitPos = hitPos or lastPos

	local tr = util.TraceHull({
		mins = -dropBounds * 0.8,
		maxs = dropBounds * 0.8,

		start = hitPos,
		endpos = hitPos - Vector(0, 0, 4096),
		filter = ignoreTable,
	})

	local dropPos = hitPos

	if tr.Hit then
		dropPos = tr.HitPos
	end

	self:SetDropOrigin(sPos)
	self:SetPos(dropPos)
end


function ENT:PlayDropSound(num, params)
	num = num or 0
	sound.Play("new2/cointoss1.ogg", self:GetDropOrigin(), 75, math.min(150, 100 + num * 15), 1)

	self:Timer("sfx", CurTime() - self:GetCreatedTime() + self.TimeToAnimate, 1, function()
		local itm = self:GetItem()
		if not itm then return end

		local rar = itm:GetRarity()
		if not rar then return end
		if not sfx[rar:GetID()] then print("no sfx for", rar:GetID()) return end

		local play = (self:EntIndex() % sfx[rar:GetID()]) + 1

		sound.Play("grp/items/imp_" .. rar:GetID() .. play .. ".mp3",
			self:GetPos() + self:OBBCenter(),
			70 + (rar:GetRarity() or 0) * 15, math.random(95, 105), 1)

	end)
end

function ENT:Think()
	if not self:CanInteract() then return end
	if self.Setup then return end

	self.Setup = true
	self:SetTrigger(true)
end

function ENT:GetItem()
	return self.Item
end

function ENT:PlayerPickup(ply)
	local tempInv = Inventory.GetTemporaryInventory(ply)
	local left, pr, newIts = tempInv:PickupItem(self:GetItem())

	if not pr then
		return
	end

	if not left then
		self.PickedUp = true
		self:Remove()
	end

	pr:Then(function()
		if not IsValid(ply) then return end
		ply:NetworkInventory(tempInv, INV_NETWORK_UPDATE)
	end)
end

function ENT:Use(ply)
	if not IsPlayer(ply) then return end
	if not self:CanInteract(ply) then return end
	self:PlayerPickup(ply)
end

function ENT:StartTouch(ply)
	if not IsPlayer(ply) then return end
	if not self:CanInteract(ply) then return end
	self:PlayerPickup(ply)
end

function ENT:EndTouch(e)

end

function ENT:OnRemove()
	if not self.Item then return end
	if self.PickedUp then return end

	self.Item:Delete()
end