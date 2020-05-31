ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.PrintName = "Mining Ore or smth"
ENT.IsOre = true 

function ENT:SetupDataTables()

	self:NetworkVar("String", 0, "Resources")
	self:NetworkVar("Int", 0, "Bops")

end
