AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/props/CS_militia/furnace01.mdl"


ENT.Refinery = true

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

util.AddNetworkString("OreRefinery")


function ENT:Think()

end

net.Receive("OreRefinery", function(len, ply)
	if not ply:Alive() then return end

	local ent = net.ReadEntity()
	local slot = net.ReadUInt(16)
	local inv = Inventory.Networking.ReadInventory()
	local item = Inventory.Networking.ReadItem(inv)

	if not inv.IsBackpack then print("inventory is not a backpack") return end

	print(ent, slot, inv, item)
end)

function ENT:SendInfo(ply)

end

function ENT:Use(ply)

	net.Start("OreRefinery")
	net.WriteEntity(self)
	net.Send(ply)
end