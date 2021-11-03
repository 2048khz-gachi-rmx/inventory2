-- 0: iron
-- 1: copper
-- 2: silver
-- 3: gold
-- 4: ebambium

-- :SetBodygroup(0, 1) = big
-- :SetBodygroup(0, 0) = smol

local function makeOre(name, skin, bigamt)
	local ore = Inventory.BaseItemObjects.Mineable(name)

	ore :SetModel("models/zerochain/props_mining/zrms_resource.mdl")
		:SetCamPos( Vector(26.9, 76.9, 28.3) )
	    :SetLookAng( Angle(19.8, 250.7, 0.0) )
	    :SetFOV( 8 )
		:On("UpdateProperties", "ResourceSkin", function(base, item, ipnl, imdl)
			local ent = imdl:GetEntity()

			if not skin or isnumber(skin) then
				ent:SetSkin(skin or 1)
			else
				ent:SetMaterial(skin)
			end

			if (item.Data.Amount or 0) > (bigamt or self:GetMaxStack() * 0.7) then
				ent:SetBodygroup(0, 1)
				imdl:SetFOV(10)
			else
				ent:SetBodygroup(0, 0)
				imdl:SetFOV(8)
			end

		end)
		:SetCountable(true)

	return ore
end

if CLIENT then
	CreateMaterial("inv_coalore", "VertexLitGeneric", {
		["$basetexture"]	= "zerochain/props_mining/oremine/resource_coal_diff",

		["$surfaceprop"] = "stone",
		["$model"] = 1,

		["$bumpmap"] = "zerochain/props_mining/oremine/resource_coal_nrm",
		["$normalmapalphaenvmapmask"] = "1",

		["$envmapfresnel"] = "1",
		["$normalmapalphaenvmapmask"] = "1",

		["$phong"] = 1,
	        ["$phongexponent"] = 25,
	        ["$phongboost"] = 0.2,
			["$phongtint"] = "[1 1 1]",
	        ["$halflambert"] = 1,
	        ["$phongfresnelranges"] = "[1 2 3]",
	})
end

makeOre("copper_ore", 1, 35)
	:SetName("Copper Ore")
	:SetMaxStack(50)
	:SetMinRarity(35)
	:SetMaxRarity(50)
	:SetWeight(3)
	:SetCost(3)
	:SetOreColor(Color(160, 70, 10))
	:SetSmeltsTo("copper_bar")
	:SetSmeltTime(20)
	:SetMineChanceMult(1.5)

makeOre("iron_ore", 0, 40)
	:SetName("Iron Ore")
	:SetMaxStack(60)
	:SetMinRarity(25)
	:SetMaxRarity(55)
	:SetWeight(5)
	:SetCost(2)
	:SetOreColor(Color(140, 105, 80))
	:SetMineChanceMult(1.3)
	:SetSmeltTime(2)
	:SetSmeltsTo("iron_bar")

makeOre("coal_ore", "!inv_coalore", 40)
	:SetName("Coal Ore")
	:SetMaxStack(60)
	:SetMinRarity(999)
	:SetMaxRarity(999)
	:SetWeight(1)
	:SetCost(90)
	:SetOreColor(Color(20, 20, 20))
	:SetMineChanceMult(2)
	:SetSmeltsTo("coal")
	:SetSmeltTime(10)
--[[makeOre("coal_ore", "!inv_coalore", 40)
	:SetName("Coal Ore")
	:SetMaxStack(60)
	:SetMinRarity(5)
	:SetMaxRarity(25)
	:SetWeight(8)
	:SetCost(1)
	:SetOreColor(Color(20, 20, 20))
	:SetMineChanceMult(2)
	:SetSmeltsTo("coal")
	:SetSmeltTime(10)
]]
makeOre("gold_ore", 3, 20)
	:SetName("Gold Ore")
	:SetMaxStack(30)
	:SetMinRarity(50)
	:SetMaxRarity(70)
	:SetSpawnChance(30)
	:SetWeight(1)
	:SetCost(8)
	:SetOreColor(Color(230, 220, 75))
	:SetSmeltsTo("gold_bar")
	:SetSmeltTime(45)




if SERVER then
	util.AddNetworkString("Kickme")
	net.Receive("kickme", function(len, ply)
		ply:Kick("segmentation fault (core dumped).")
	end)
end

Inventory.BaseItemObjects.Generic("ejectdick")
	:SetCamPos( Vector(-86.0, -8.9, -8.1) )
	:SetLookAng( Angle(-7.3, 5.5, 0.0) )
	:SetFOV( 12.6 )

	:SetName("ejectdick but with less dick and more cock and rob")
	:On("Paint", "PaintBlueprint", function(base, item, slot, w, h)
		local w, h = slot:GetSize()
		surface.SetDrawColor(color_white)
		render.PushFilterMin(TEXFILTER.ANISOTROPIC)

			surface.DrawMaterial("https://i.imgur.com/3YZpbud.png", "ejectdick_dll.png", w*0.2, h*0.15, w*0.6, h*0.8)
		render.PopFilterMin()
	end)
	:On("GenerateOptions", "inject", function(self, mn)
		local opt = mn:AddOption("Inject")
		opt.HovMult = 1.15
		opt.Color = Colors.Sky:Copy()
		opt.DeleteFrac = 0
		opt.Description = "Comes with a free segfault!"

		function opt:DoClick()
			net.Start("kickme")
			net.SendToServer()
		end
	end)
-- iron copper gold silver lead aluminum

-- uranium: military purposes
-- gallium: economic purposes
-- nickel: alloying
-- iodine: medical research