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

	if not Inventory.Inventories.Entity then self:Remove() return end --created too early?

	self.Queue = {}
	self.Inventory = {Inventory.Inventories.Entity:new(self), Inventory.Inventories.Entity:new(self)}

	self.OreInput = self.Inventory[1] --shortcuts
	self.OreInput.MaxItems = self.MaxQueues

	self.OreOutput = self.Inventory[2]
	self.OreOutput.MaxItems = 5

	hook.Once("CPPIAssignOwnership", ("cppiInv:%p"):format(self), function(ply, ent)
		if ent ~= self then return end
		self.OreInput.OwnerUID = ply:SteamID64()
		self.OreOutput.OwnerUID = ply:SteamID64()
	end)
end

util.AddNetworkString("OreRefinery")


function ENT:Think()

end

function ENT:QueueRefine(ply, item, slot)

end

net.Receive("OreRefinery", function(len, ply)
	if not ply:Alive() then return end

	local ent = net.ReadEntity()
	local self = ent

	local typ = net.ReadUInt(4)

	if typ == 0 then --deposit
		local slot = net.ReadUInt(16)
		local inv = Inventory.Networking.ReadInventory()
		local item = Inventory.Networking.ReadItem(inv)

		if not inv.IsBackpack then print("inventory is not a backpack") return end
		if not item then print("didn't get item") return end
		ent:QueueRefine(ply, item, slot)

		if slot > self.OreInput.MaxItems then print("slot higher than max", slot, self.OreInput.MaxItems) return end

		item:SetAmount(item:GetAmount() - 1)

		self.OreInput:NewItem(item:GetItemID(), function()
			Inventory.Networking.NetworkInventory(ents.FindInPVS(self), self.OreInput)
		end, slot, item:GetData(), true)

	elseif typ == 1 then --withdraw

	end

end)

function ENT:SendInfo(ply)

end

function ENT:Use(ply)

	net.Start("OreRefinery")
		net.WriteEntity(self)
		net.WriteUInt(0, 4)
	net.Send(ply)
end