--

local el = Inventory.Modifiers.Pool.Sonar
	:SetOnActivate(function(base, ply)
		local mod = base:GetModFromPlayer(ply)
		if not mod then return end

		print("lol activating", ply, mod)
		--base:RequestAction()
		ply:EmitSound("test/deploy" .. math.random(1, 3) .. ".mp3", 50, math.random(90, 110), 0.7)
		-- sound dur is 0.375
		ply:LiveTimer("Sonar_Sound", 0.25, function()
			ply:EmitSound("test/servo" .. math.random(1, 3) .. ".mp3", 50, math.random(100, 100), 0.7)
		end)

		ply:LiveTimer("Sonar", 0.8, function()
			ply:EmitSound("test/sonarfire.mp3", 85, math.random(100, 100))
			ply:ViewPunch(Angle(math.Rand(-2, -5), math.Rand(2, -2), 0))
			ply:SetViewPunchVelocity(Angle(-45, math.Rand(15, -15)))

			local ent = ents.Create("sonar")
			ent:SetPos(ply:EyePos()
				+ ply:EyeAngles():Right() * -4
				+ ply:EyeAngles():Forward() * -32
				+ ply:EyeAngles():Up() * 2)
			ent:SetOwner(ply)

			local ang = ply:EyeAngles()
			ang:RotateAroundAxis(ang:Right(), 90)

			ent:SetAngles(ang)

			ent:Spawn()
			ent:Activate()
			ent:Timer("r", 4, function() ent:Remove() end)


			local p = ent:GetPhysicsObject()
			p:SetVelocity(ply:EyeAngles():Forward() * 1400 + vector_up * 16)

			ply:LiveTimer("Sonar_Finish", 0.4, function()
				ply:EmitSound("test/finish" .. math.random(1, 3) .. ".mp3",
					50, math.random(90, 110), 0.7)
			end)
		end)
		return true
	end)