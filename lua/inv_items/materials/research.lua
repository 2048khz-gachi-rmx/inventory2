Inventory.BaseItemObjects.Generic("stem_cells")
	:SetName("Stem Cells") -- makes zero fucking sense that "stem cells" would be a limited item but
	-- you know what? fuckin whatever, i really have no better ideas...
	:SetModel("models/healthvial.mdl")
	:SetModelColor(Color(255, 90, 90))
	:SetColor(Color(190, 60, 80))

	:SetCamPos( Vector(-30.5, -72.8, 32.5) )
	:SetLookAng( Angle(19.4, -292.8, 0.0) )
	:SetFOV( 7 )

	:SetCountable(true)
	:SetMaxStack(15)
	:SetShouldSpin(false)

	:SetRarity("uncommon")

Inventory.BaseItemObjects.Generic("blood_nanobots")
	:SetName("Bloodstream Nanobots")
	:SetModel("models/jaanus/wiretool/wiretool_grabber_forcer.mdl")
	:SetModelColor(Color(125, 170, 90))
	:SetColor(Color(125, 170, 90))

	:SetCamPos( Vector(-1.9, -13.0, -4.2) )
	:SetLookAng( Angle(210.8, -98.4, 0.0) )
	:SetFOV( 70.0 )

	:SetCountable(true)
	:SetMaxStack(10)
	:SetShouldSpin(false)

	:SetCamPos( Vector(39.5, 58.0, -13.2) )
	:SetLookAng( Angle(-166.7, 56.3, 0.0) )
	:SetFOV( 13.3 )

	:On("UpdateModel", "ResourceSkin", function(base, item, ent)
		ent:SetMaterial("phoenix_storms/MetalSet_1-2")
	end)

	:SetRarity("rare")