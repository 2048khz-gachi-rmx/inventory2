ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.PrintName = "Mining Ore or smth"
ENT.IsOre = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 1, "Resources")
	self:NetworkVar("Int", 1, "Rarity") -- todo: network as an enum, not a raw rarity value
										-- take into consideration what ores spawned (their rarity value compared to rest of the pool, eg top 30%, top 10%, top 5% ores)
	if CLIENT then
		self:On("DTChanged", "ResourceTrack", self.UpdateOres)
	end
end

AddCSLuaFile("oremark_cl.lua")

hook.Add("LibItUp", "LoadOremark", function(lib)
	print(lib)
	lib.OnInitEntity(Curry(include, "oremark" .. (SERVER and "_sv" or "_cl") .. ".lua"))
end)