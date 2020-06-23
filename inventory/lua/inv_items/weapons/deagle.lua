local deag = Inventory.BaseItemObjects.Weapon:new("arccw_deagle")

deag	:SetName("Deagle")
		:SetModel("models/weapons/arccw/w_gce.mdl")
		:SetWeaponClass("arccw_deagle50")

		:SetCamPos( Vector(3.5, -34, 6.7) )
	    :SetLookAng( Angle(5.9, 90.4, 20) )
	    :SetFOV( 19 )

		:SetShouldSpin(false)

		:SetEquipSlot("secondary")