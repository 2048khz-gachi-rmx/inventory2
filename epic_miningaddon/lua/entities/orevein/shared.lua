ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.PrintName = "Mining Ore or smth"
ENT.IsOre = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 1, "Resources")

	if CLIENT then
		self:On("DTChanged", "ResourceTrack", self.UpdateOres) --self:NetworkVarNotify("Resources", self.UpdateOres)
	end
end

AddCSLuaFile("oremark_cl.lua")
hook.Add("LibItUp", "LoadOremark", function(lib)
	print(lib)
	lib.OnInitEntity(Curry(include, "oremark" .. (SERVER and "_sv" or "_cl") .. ".lua"))
end)