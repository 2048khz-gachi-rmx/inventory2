AddCSLuaFile()
ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "Base Lootable"
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.Model = "models/props/cs_assault/washer_box2.mdl"
ENT.Skin = 0
ENT.IsLootableBoks = true

function ENT:SetupDataTables()

end

function ENT:CanInteract(ply)
	return ply:GetEyeTrace().Entity == self and ply:GetEyeTrace().Fraction * 32768 < 96 and ply:Alive()
end

function ENT:Initialize()
	self:DrawShadow(false)
	self._Initialized = true

	self.Inventory = {Inventory.Inventories.Entity:new(self)}
	self.Storage = self.Inventory[1]
	self.Storage.UseOwnership = false

	self.Storage.ActionCanCrossInventoryFrom = function(inv, ply, item, invTo)
		if not invTo.IsBackpack then return false end
		if not inv:GetOwner():CanInteract(ply) then return false end

		return true
	end

	-- fuck you you will do nothing except move from
	self.Storage.ActionCanInteract = function(inv, ply, act, invTo)
		return false
	end

	if CLIENT then
		self:CLInit()
	else
		self:SVInit()
	end
end

-- for easylua create()
hook.Add("CPPIAssignOwnership", "NoLootOwner", function(ply, ent)
	if IsValid(ent) and ent.IsLootableBoks then return false end
end)