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
	:SetBaseTransferCost(25000)

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

Inventory.BaseItemObjects.Generic("wepkit")
	:SetName("Gunsmith Kit")
	:SetModel("models/maver1k_xvii/stalker/props/devices/dev_merger.mdl")
	:SetColor(Color(230, 230, 230))

	:SetCamPos( Vector(59, -48.7, 46.5) )
	:SetLookAng( Angle(29.2, -219.4, 0.0) )
	:SetFOV( 12.5 )

	:SetCountable(true)
	:SetMaxStack(3)
	:SetBaseTransferCost(75000)
	:SetRarity("rare")

Inventory.BaseItemObjects.Generic("nanotubes")
	:SetModel("models/Items/CrossbowRounds.mdl")
	:SetName("Carbon Nanotubes")
	:SetModelColor(Color(250, 250, 250))
	:SetColor(Color(75, 75, 75))

	:SetCamPos( Vector(-63.3, 56.6, 16.0) )
	:SetLookAng( Angle(11.3, -42.3, 0.0) )
	:SetFOV( 11.0 )

	:SetShouldSpin(false)

	:SetCountable(true)
	:SetMaxStack(50)
	:SetBaseTransferCost(5000)
	:SetRarity("uncommon")

	:On("UpdateModel", "ResourceSkin", function(base, item, ent, inPnl)
		ent:SetMaterial("phoenix_storms/metalset_1-2")
	end)

Inventory.BaseItemObjects.Generic("ionbat")
	:SetModel("models/lt_c/sci_fi/lantern.mdl")
	:SetName("Ion Accumulator")
	:SetModelColor(Color(70, 160, 250):MulHSV(1, 0.5, 1.3))
	:SetColor(Color(230, 220, 80))

	:SetCamPos( Vector(60.5, -47.1, 37.6) )
	:SetLookAng( Angle(23.5, -217.9, 0.0) )
	:SetFOV( 8.4 )

	:SetShouldSpin(false)

	:SetCountable(true)
	:SetMaxStack(5)
	:SetBaseTransferCost(35000)
	:SetRarity("uncommon")
