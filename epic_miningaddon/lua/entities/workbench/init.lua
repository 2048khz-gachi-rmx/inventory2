AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("bp_menu.lua")
AddCSLuaFile("recipe_menu.lua")

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

end

util.AddNetworkString("Workbench")

function ENT:SendInfo(ply)

	net.Start("Workbench")
		net.WriteEntity(self)
	net.Send(ply)

end

function ENT:Use(ply)
	self:SendInfo(ply)
end