include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

function SWEP:Reload()

end

function SWEP:Think()
end

local snd = "physics/concrete/concrete_impact_%s%s.wav"

function SWEP:SVPrimaryAttack(ply, ore)

	local ores = ore.Ores
	local mined = false

	for k,v in pairs(ores) do
		local chance = math.random()
		local succ = chance >= self.FailChance / v.ore:GetMineChanceMult()

		if succ then
			ore:MineOut(k, ply)
			mined = true
		end

	end

	local snd = snd

	if mined == true then
		ore:NetworkOres()
		snd = snd:format("hard", math.random(1, 3))
	else
		snd = snd:format("soft", math.random(1, 3))
	end

	ore:EmitSound(snd, (mined and 150) or 140, math.random(90, 110), (mined and 1) or 0.8, CHAN_AUTO)

end
