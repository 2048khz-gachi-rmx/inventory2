include("shared.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

function ENT:SVInit()
	self:SetModel(self.Model)
	self:SetSkin(self.Skin)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:GetPhysicsObject():EnableMotion(false)
	self:SetRenderMode(RENDERMODE_TRANSALPHA)

	--self:PhysWake()
	self:Activate()
end

function ENT:Think()
	if not self:CanInteract() then return end
	if self.Setup then return end

	self.Setup = true
end

function ENT:OnRemove()
	-- TODO: remove all items inside
end

function ENT:Use(ply)
	if not IsPlayer(ply) then return end
end