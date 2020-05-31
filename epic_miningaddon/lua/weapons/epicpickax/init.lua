include("shared.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_init.lua")

/*---------------------------------------------------------
	Reload does nothing
---------------------------------------------------------*/
function SWEP:Reload()

end
 
/*---------------------------------------------------------
  Think does nothing
---------------------------------------------------------*/
function SWEP:Think()	
end
 
/*---------------------------------------------------------
	PrimaryAttack
---------------------------------------------------------*/
local snd = "physics/concrete/concrete_impact_%s%s.wav"

function SWEP:SVPrimaryAttack(ply, ore)

	local ores = ore.Ores 

	local mined = false 

	for k,v in pairs(ores) do 
		local chance = v.MineChance
		local waste = v.WasteChance
		local amt = v.MineAmount or 1

		local rand = math.random(0, 100) <= chance
		local wrand = math.random(0, 100) <= waste

		if wrand then 
			v.Richness = v.Richness - 1
			if v.Richness <= 0 then ores[k] = nil end

			ore:NetworkOres()
		end

		if rand then 
			ply:GiveItem(k, {Amount = amt}, nil, ply.Inventory.Temp, "ply_tempinv")
			mined = true
		end

	end
	local snd = snd

	if mined == true then 
		snd = snd:format("hard", math.random(1, 3))
	else 
		snd = snd:format("soft", math.random(1, 3))
	end 

	ore:EmitSound(snd, (mined and 150) or 140, math.random(90, 110), (mined and 1) or 0.8, CHAN_AUTO)

end
