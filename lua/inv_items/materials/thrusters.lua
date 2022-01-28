--

Inventory.BaseItemObjects.Generic("thruster_t1")
	:SetName("Basic Thruster")
	:SetModel("models/xqm/afterburner1.mdl")
	:SetColor(Color(210, 200, 110))

	:SetCamPos( Vector(-87.8, 0.0, -1.7) )
	:SetLookAng( Angle(0.0, 0.0, 0.0) )
	:SetFOV( 18.7 )

	:SetCountable(true)
	:SetMaxStack(10)
	:SetRarity("uncommon")

Inventory.BaseItemObjects.Generic("thruster_t2")
	:SetName("Ion Thruster")
	:SetModel("models/thrusters/jetpack.mdl")
	:SetColor(Color(210, 200, 110))

	:SetCamPos( Vector(44.7, 53.2, -31.3) )
	:SetLookAng( Angle(-26.5, -129.8, 180.0) )
	:SetFOV( 15.7 )

	:SetCountable(true)
	:SetMaxStack(5)
	:SetRarity("rare")

--[[Inventory.BaseItemObjects.Generic("adhesive")
	:SetName("Adhesive")
	:SetModel("models/props_junk/plasticbucket001a.mdl")
	:SetModelColor(Color(90, 75, 45))
	:SetColor(Color(90, 75, 45):MulHSV(1, 1.2, 1.6))

	:SetCamPos( Vector(47.6, -60.8, 38.0) )
	:SetLookAng( Angle(23.7, -231.8, 0.0) )
	:SetFOV( 22.2 )

	:SetCountable(true)
	:SetMaxStack(10)


Inventory.BaseItemObjects.Generic("adhesive")
	:SetName("Adhesive")
	:SetModel("models/props_junk/plasticbucket001a.mdl")
	:SetModelColor(Color(90, 75, 45))
	:SetColor(Color(90, 75, 45):MulHSV(1, 1.2, 1.6))

	:SetCamPos( Vector(47.6, -60.8, 38.0) )
	:SetLookAng( Angle(23.7, -231.8, 0.0) )
	:SetFOV( 22.2 )

	:SetCountable(true)
	:SetMaxStack(10)]]