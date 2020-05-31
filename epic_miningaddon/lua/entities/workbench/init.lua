AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/props/CS_militia/table_shed.mdl"

local me = {}


function ENT:Initialize()
	self:SetModel(self.Model)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	self:DrawShadow(false)

	self:SetModelScale(1)
	local phys = self:GetPhysicsObject()

	if (phys:IsValid()) then
		phys:Wake()
		phys:EnableMotion(true)
	end

	me[self] = {}
	local me = me[self]

end
util.AddNetworkString("Workbench")
function ENT:SendInfo(ply)

	local me = RefineryTbl[self]
	
	net.Start("Workbench")
		net.WriteEntity(self)
	net.Send(ply)


end

function ENT:Use(ply)

	local me = me[self]
	if not me then self:Initialize() return end

	self:SendInfo(ply)
	
end