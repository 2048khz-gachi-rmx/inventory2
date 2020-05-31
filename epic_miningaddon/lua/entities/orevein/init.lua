AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


ENT.Model = "models/props/cs_militia/militiarock0%s.mdl"

OreRespawnTime = 300 --seconds


local size = {
	[1] = 3,
	[2] = 3,
	[3] = 2,
	[5] = 1
}

function ENT:Initialize()
	local rand = math.random(1,4)
	if rand==4 then rand=5 end
	self.Size = size[rand]

	self.RichQuota = self.Size * 35
	self.MaxRich = self.Size * 70

	self.Richness = 0

	self:SetModel(string.format(self.Model, rand))

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)
	--self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	self:DrawShadow(false)
	self:SetModelScale(1)
	self.Ores = {}

	self.TimesGenerated = 0
	local phys = self:GetPhysicsObject()

	if (phys:IsValid()) then
		phys:Wake()
		phys:EnableMotion(true)
	end

	self:GenerateOres()

end

function ENT:FindConflicts(fin, confl)

end

function ENT:ApplyOres(tbl)

end

function ENT:GenerateOres()

end

function ENT:NetworkOres()

end

function OresRespawn()

end

if CurTime() > 60 then
	OresRespawn()
else

	local invready = false
	local entsready = false

	hook.Add("OnInvLoad", "SpawnOres", function()	--only after inventory is ready
		if entsready then OresRespawn() end
		invready = true
	end)

	hook.Add("InitPostEntity", "SpawnOres", function()
		if invready then OresRespawn() end
		entsready = true
	end)
end