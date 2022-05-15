Inventory.BaseItemObjects.Generic("wire")
	:SetName("Copper Wire")
	:SetModel("models/z-o-m-b-i-e/st/big_object/st_katushka_03.mdl")
	:SetColor(Color(190, 110, 125))

	:SetCamPos( Vector(71.5, -131.3, 80.1) )
	:SetLookAng( Angle(20.9, 121.0, 90.0) )
	:SetFOV( 50.4 )

	:SetCountable(true)
	:SetMaxStack(25)
	:SetBaseTransferCost(7500)

	:SetRarity("common")

	:On("UpdateModel", "ResourceSkin", function(base, item, ent, inPnl)
		if not inPnl then
			ent:SetModelScale(0.2)
		end
	end)

Inventory.BaseItemObjects.Generic("circuit_board")
	:SetName("Circuit Board")
	:SetModel("models/props_junk/garbage_carboard002a.mdl") -- could pass?
	:SetModelColor(Color(190, 190, 190))

	:SetCamPos( Vector(-51.0, -29.1, 35.9) )
	:SetLookAng( Angle(30.6, 29.9, 0.0) )
	:SetFOV( 43.6 )

	:SetCountable(true)
	:SetMaxStack(10)

	:On("UpdateModel", "ResourceSkin", function(base, item, ent)
		ent:SetMaterial("phoenix_storms/wire/pcb_green")
	end)

	:SetRarity("uncommon")

Inventory.BaseItemObjects.Generic("capacitor")
	:SetName("Capacitor")
	:SetModel("models/cyborgmatt/capacitor_large.mdl")
	:SetModelColor(Color(220, 220, 220))

	:SetCamPos( Vector(62.4, 32.6, 50.7) )
	:SetLookAng( Angle(24.9, -152.5, 0.0) )
	:SetFOV( 32.8 )

	:SetCountable(true)
	:SetMaxStack(25)
	:SetBaseTransferCost(1000)

	:SetRarity("uncommon")

-- its supposed to be small, aight?
Inventory.BaseItemObjects.Generic("radiator")
	:SetName("Radiator")
	:SetModel("models/props_interiors/radiator01a.mdl")

	:SetCamPos( Vector(45.1, -1.5, 82.4) )
	:SetLookAng( Angle(120.6, -0.1, -10.0) )
	:SetFOV( 32.2 )

	:SetShouldSpin(false)

	:SetCountable(true)
	:SetMaxStack(5)
	:On("UpdateModel", "ResourceSkin", function(base, item, ent)
		ent:SetSkin(1)
	end)

	:SetRarity("uncommon")


Inventory.BaseItemObjects.Generic("weaponparts")
	:SetName("Weapon Parts")
	:SetModel("models/z-o-m-b-i-e/st/equipment_cache/st_equipment_instrument_01.mdl")
	:SetColor(Color(120, 140, 160))

	:SetCamPos( Vector(44.7, 70.3, 31.5) )
	:SetLookAng( Angle(18.9, -122.4, 0.0) )
	:SetFOV( 13.3 )

	:SetCountable(true)
	:SetMaxStack(5)
	:SetBaseTransferCost(25000)
	:On("UpdateModel", "ResourceSkin", function(base, item, ent, inPnl)
		ent:SetSubMaterial(1, "Models/effects/vol_light001") -- ugly hack but oldschool, lol
		if not inPnl then
			ent:SetModelScale(0.8)
		end
	end)

	:SetRarity("uncommon")

-- models/z-o-m-b-i-e/st/box/st_box_metall_01.mdl

Inventory.BaseItemObjects.Generic("laserdiode")
	:SetName("Laser Diode")
	:SetModel("models/jaanus/wiretool/wiretool_beamcaster.mdl")
	:SetColor(Color(250, 80, 80))
	:SetCamPos( Vector(-70.3, 3.2, 33.6) )
	:SetLookAng( Angle(22.6, -2.6, -30.0) )
	:SetFOV( 11.1 )

	:SetCountable(true)
	:SetMaxStack(20)
	:SetBaseTransferCost(15000)
	:On("UpdateModel", "ResourceSkin", function(base, item, ent, inPnl)
		--ent:SetMaterial("models/props_combine/health_charger_glass")
	end)

	:SetRarity("uncommon")

Inventory.BaseItemObjects.Generic("lube")
	:SetName("Lubricant")
	:SetModel("models/props_junk/garbage_plasticbottle002a.mdl")
	:SetModelColor(Color(45, 100, 60))
	:SetColor(Color(45, 100, 60):MulHSV(1, 1.2, 1.6))

	:SetCamPos( Vector(64.2, 53.3, 23.3) )
	:SetLookAng( Angle(15.6, -140.3, 0.0) )
	:SetFOV( 14.1 )

	:SetCountable(true)
	:SetMaxStack(10)
	:SetBaseTransferCost(10000)
	:SetRarity("uncommon")


--[[
-- big black tube, kinda like a graphite rod in mc

:SetModel("models/hunter/tubes/tube1x1x6.mdl")
	:SetModelColor(Color(250, 250, 250))
	:SetColor(Color(75, 75, 75):MulHSV(1, 1.2, 1.6))

	:SetCamPos( Vector(-250.3, -0.0, 142.4) )
	:SetLookAng( Angle(0.0, 0.0, 45.0) )
	:SetFOV( 50.3 )

	:SetShouldSpin(false)

	:SetCountable(true)
	:SetMaxStack(50)
	:SetBaseTransferCost(5000)
	:SetRarity("uncommon")

	:On("UpdateModel", "ResourceSkin", function(base, item, ent, inPnl)
		local mx = Matrix()
		mx:ScaleNumber(0.5, 0.5, 1)
		ent:EnableMatrix("RenderMultiply", mx)
		ent:SetMaterial("phoenix_storms/metalset_1-2")
	end)
]]

--[[
Inventory.BaseItemObjects.Generic("adhesive")
	:SetName("Adhesive")
	:SetModel("models/props_junk/plasticbucket001a.mdl")
	:SetModelColor(Color(90, 75, 45))
	:SetColor(Color(90, 75, 45):MulHSV(1, 1.2, 1.6))

	:SetCamPos( Vector(47.6, -60.8, 38.0) )
	:SetLookAng( Angle(23.7, -231.8, 0.0) )
	:SetFOV( 22.2 )

	:SetCountable(true)
	:SetMaxStack(10)
]]

Inventory.BaseItemObjects.Generic("rdx")
	:SetName("RDX")
	:SetModel("models/props_lab/jar01b.mdl")

	:SetCamPos( Vector(-52.6, -66.7, 16.6) )
	:SetLookAng( Angle(11.0, 51.7, 0.0) )
	:SetFOV( 9.4 )

	:SetCountable(true)
	:SetMaxStack(5)
