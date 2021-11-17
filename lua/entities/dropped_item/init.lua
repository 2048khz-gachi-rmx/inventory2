include("shared.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

util.AddNetworkString("dropped_item_itm")

function ENT:SVInit()
	if not self.Item and SERVER then
		self:Remove()
		errorf("missing item")
		return
	end

	self:SetCreationTime(CurTime())
	self:SetModel(self.Model)
	self:SetSkin(self.Skin)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:GetPhysicsObject():EnableMotion(false)
	self:SetRenderMode(RENDERMODE_TRANSALPHA)

	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
	--self:SetTrigger(true)

	self:SetUseType(SIMPLE_USE)

	--self:PhysWake()
	self:Activate()
end

function ENT:GetItem()
	return self.Item
end

function ENT:StartTouch(e)
	print("dont touch me there", e)
end

function ENT:EndTouch(e)
	print("ow ow ow", e)
end

function ENT:OnRemove()
	if not self.Item then return end
	if self.PickedUp then return end

	self.Item:Delete()
end