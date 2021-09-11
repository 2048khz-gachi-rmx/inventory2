ENT.Type = "anim"
ENT.Base = "bw_base_electronics"
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.PrintName = "Workbench"
ENT.IsWorkbench = true

function ENT:DerivedDataTables()
	self:NetworkVar("Int", 0, "CurRecipe")
	self:NetworkVar("Float", 0, "FinishTime")
end
