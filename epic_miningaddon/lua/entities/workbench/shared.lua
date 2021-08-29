ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.PrintName = "Workbench"
ENT.IsWorkbench = true

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "CurRecipe")
	self:NetworkVar("Float", 0, "FinishTime")
end
