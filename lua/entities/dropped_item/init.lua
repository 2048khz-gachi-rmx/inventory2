include("shared.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")


function ENT:SVInit()
	if not self.Item and SERVER then
		self:Remove()
		errorf("missing item")
		return
	end

	self:SetNWItemID(self.Item:GetIID())
	self:SetCreationTime(CurTime())
	self:SetModel(self.Model)
	self:SetSkin(self.Skin)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:GetPhysicsObject():EnableMotion(false)
	self:SetRenderMode(RENDERMODE_TRANSALPHA)

	self:SetUseType(SIMPLE_USE)

	--self:PhysWake()
	self:Activate()
end

function ENT:OnRemove()
	if not self.Item then return end
	if self.PickedUp then return end

	self.Item:Delete()
end