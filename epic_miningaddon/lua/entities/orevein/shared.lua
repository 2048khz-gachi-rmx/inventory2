ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.PrintName = "Mining Ore or smth"
ENT.IsOre = true

function ENT:SetupDataTables()
	self:NetworkVar("Int", 1, "Resources")

	if CLIENT then
		self:NetworkVarNotify("Resources", self.UpdateOres)
	end
end
