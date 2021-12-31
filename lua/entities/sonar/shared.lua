AddCSLuaFile()
ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "Sonar"

ENT.Model = "models/props_combine/combine_mine01.mdl"
ENT.DefaultRadius = 512
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
	self:NetworkVar("Float", 0, "LandTime")
	self:NetworkVar("Int", 0, "ScanRadius")

	self:SetScanRadius(self.DefaultRadius)
end