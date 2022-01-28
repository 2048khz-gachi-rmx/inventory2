--

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

Inventory.BaseItemObjects.Generic("cpu")
	:SetName("Processor")
	:SetModel("models/cheeze/wires/cpu.mdl")
	:SetColor(Color(220, 220, 220))

	:SetCamPos( Vector(58.7, -37.7, 51.2) )
	:SetLookAng( Angle(36.1, -212.7, 0.0) )
	:SetFOV( 4.7 )

	:SetCountable(true)
	:SetMaxStack(10)

	:SetRarity("rare")

Inventory.BaseItemObjects.Generic("tgt_finder")
	:SetName("Locator")
	:SetModel("models/beer/wiremod/targetfinder.mdl")
	:SetColor(Color(60, 180, 250))

	:SetCamPos( Vector(-39.5, -67.7, 36.7) )
	:SetLookAng( Angle(24.7, 59.8, 0.0) )
	:SetFOV( 9.5 )

	:SetCountable(true)
	:SetMaxStack(5)

	:SetRarity("rare")

Inventory.BaseItemObjects.Generic("emitter")
	:SetName("Emitter")
	:SetModel("models/cheeze/wires/wireless_card.mdl")
	:SetColor(Color(80, 220, 80))

	:SetCamPos( Vector(-38.3, -65.7, 42.2) )
	:SetLookAng( Angle(28.5, 59.3, 0.0) )
	:SetFOV( 8.9 )

	:SetCountable(true)
	:SetMaxStack(5)

	:SetRarity("rare")


--[[
Inventory.BaseItemObjects.Generic("nutsbolts")
	:SetName("Nuts & Bolts")
	:SetModel("models/items/sniper_round_box.mdl")
	:SetColor(Color(120, 140, 160))

	:SetCamPos( Vector(-48.8, 65.2, 35.2) )
	:SetLookAng( Angle(21.5, -53.5, 0.0) )
	:SetFOV( 5.0 )

	:SetCountable(true)
	:SetMaxStack(10)
	:On("UpdateModel", "ResourceSkin", function(base, item, ent, inPnl)
		ent:SetSubMaterial(1, "Models/effects/vol_light001") -- ugly hack but oldschool, lol
		if not inPnl then
			ent:SetModelScale(1.5)
		end
	end)
]]

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
