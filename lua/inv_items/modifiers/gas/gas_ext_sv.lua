--

function Inventory.LaunchSonar(ply)
	local wep = ply:GetActiveWeapon()

	ply:LiveTimer("MendGas_Deploy", 0.25, function()
		
	end)

end

local el = Inventory.Modifiers.Pool.Sonar
	:SetOnActivate(function(base, ply, mod)
		Inventory.LaunchSonar(ply)
		return true
	end)