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

	:On("UpdateProperties", "ResourceSkin", function(base, item, ipnl, imdl)
		local ent = imdl:GetEntity()
		ent:SetMaterial("phoenix_storms/wire/pcb_green")
	end)

Inventory.BaseItemObjects.Generic("capacitor")
	:SetName("Capacitor")
	:SetModel("models/cyborgmatt/capacitor_large.mdl")
	:SetModelColor(Color(220, 220, 220))

	:SetCamPos( Vector(62.4, 32.6, 50.7) )
	:SetLookAng( Angle(24.9, -152.5, 0.0) )
	:SetFOV( 32.8 )

	:SetCountable(true)
	:SetMaxStack(25)

Inventory.BaseItemObjects.Generic("cpu")
	:SetName("Processor")
	:SetModel("models/cheeze/wires/cpu.mdl")

	:SetCamPos( Vector(58.7, -37.7, 51.2) )
	:SetLookAng( Angle(36.1, -212.7, 0.0) )
	:SetFOV( 4.7 )

	:SetCountable(true)
	:SetMaxStack(10)

Inventory.BaseItemObjects.Generic("tgt_finder")
	:SetName("Locator")
	:SetModel("models/beer/wiremod/targetfinder.mdl")

	:SetCamPos( Vector(-39.5, -67.7, 36.7) )
	:SetLookAng( Angle(24.7, 59.8, 0.0) )
	:SetFOV( 9.5 )

	:SetCountable(true)
	:SetMaxStack(5)

Inventory.BaseItemObjects.Generic("emitter")
	:SetName("Emitter")
	:SetModel("models/cheeze/wires/wireless_card.mdl")

	:SetCamPos( Vector(-38.3, -65.7, 42.2) )
	:SetLookAng( Angle(28.5, 59.3, 0.0) )
	:SetFOV( 8.9 )

	:SetCountable(true)
	:SetMaxStack(5)

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
	:On("UpdateProperties", "ResourceSkin", function(base, item, ipnl, imdl)
		local ent = imdl:GetEntity()
		ent:SetSkin(1)
	end)

Inventory.BaseItemObjects.Generic("nutsbolts")
	:SetName("Nuts & Bolts")
	:SetModel("models/items/sniper_round_box.mdl")

	:SetCamPos( Vector(-48.8, 65.2, 35.2) )
	:SetLookAng( Angle(21.5, -53.5, 0.0) )
	:SetFOV( 5.0 )

	:SetCountable(true)
	:SetMaxStack(10)
	:On("UpdateProperties", "ResourceSkin", function(base, item, ipnl, imdl)
		local ent = imdl:GetEntity()
		ent:SetSubMaterial(1, "Models/effects/vol_light001") -- ugly hack but oldschool, lol
	end)

Inventory.BaseItemObjects.Generic("rdx")
	:SetName("RDX")
	:SetModel("models/props_lab/jar01b.mdl")

	:SetCamPos( Vector(-52.6, -66.7, 16.6) )
	:SetLookAng( Angle(11.0, 51.7, 0.0) )
	:SetFOV( 9.4 )

	:SetCountable(true)
	:SetMaxStack(5)
