AddCSLuaFile()
ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "Sonar"

ENT.Model = "models/props_combine/combine_mine01.mdl"

if SERVER then
	function ENT:Initialize()
		self:SetModel(self.Model)

		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)

		self:PhysWake()
		self:Activate()
		self:SetModelScale(0.25, 0)

		local p = self:GetPhysicsObject()
		p:SetMass(800)
		p:SetDamping(0, 2)
		p:SetDragCoefficient(0)
	end
end