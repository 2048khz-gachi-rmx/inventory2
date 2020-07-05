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
		:On("SetInSlot", "ResourceSkin", function(base, item, ipnl, imdl)
			local ent = imdl:GetEntity()

			if not skin or isnumber(skin) then
				ent:SetSkin(skin or 1)
			else
				ent:SetSubMaterial(1, skin)
			end

			if item.Data.Amount > (bigamt or self:GetMaxStack() * 0.7) then
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
	CreateMaterial("mining_coal4", "VertexLitGeneric", {

		["$basetexture"]	= "zerochain/props_mining/zrms_coalpiece",

		["$surfaceprop"] = "stone",
		["$model"] = 1,


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

makeOre("iron_ore", 0, 40)
	:SetName("Iron Ore")
	:SetMaxStack(60)
	:SetMinRarity(25)
	:SetMaxRarity(55)
	:SetWeight(5)
	:SetCost(2)
	:SetOreColor(Color(140, 105, 80))

makeOre("coal_ore", "!mining_coal4", 40)
	:SetName("Coal Ore")
	:SetMaxStack(60)
	:SetMinRarity(5)
	:SetMaxRarity(25)
	:SetWeight(8)
	:SetCost(1)
	:SetOreColor(Color(20, 20, 20))

makeOre("gold_ore", 3, 20)
	:SetName("Gold Ore")
	:SetMaxStack(30)
	:SetMinRarity(50)
	:SetMaxRarity(70)
	:SetSpawnChance(30)
	:SetWeight(1)
	:SetCost(8)
	:SetOreColor(Color(230, 220, 75))

-- iron copper gold silver lead aluminum

-- uranium: military purposes
-- gallium: economic purposes
-- nickel: alloying
-- iodine: medical research