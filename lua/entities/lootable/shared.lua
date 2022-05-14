AddCSLuaFile()
ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "Base Lootable"
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.Model = "models/props/cs_assault/washer_box2.mdl"
ENT.Skin = 0

local function notInitted(self)
	if self._Initialized then
		error("do it before spawn")
		return
	end
end

function ENT:SetupDataTables()

end

function ENT:CanInteract(ply)
	return ply:GetEyeTrace().Entity == self and ply:GetEyeTrace().Fraction * 32768 < 96
end

function ENT:Initialize()
	self:DrawShadow(false)
	self._Initialized = true

	self.Inventory = {Inventory.Inventories.Entity:new(self)}

	if CLIENT then
		self:CLInit()
	else
		self:SVInit()
	end
end
