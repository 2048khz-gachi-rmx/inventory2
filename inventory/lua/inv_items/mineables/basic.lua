-- 0: iron
-- 1: copper
-- 2: silver
-- 3: gold
-- 4: ebambium

-- :SetBodygroup(0, 1) = big
-- :SetBodygroup(0, 0) = smol

local ore = Inventory.BaseItemObjects.Mineable("copper_ore")
ore 	:SetName("Copper Ore")
		:SetModel("models/zerochain/props_mining/zrms_resource.mdl")
		:SetCamPos( Vector(26.9, 76.9, 28.3) )
	    :SetLookAng( Angle(19.8, 250.7, 0.0) )
	    :SetFOV( 8 )
		:On("SetInSlot", function(base, item, ipnl, imdl)
			imdl:SetColor(item.Data.Color or color_white)
			local ent = imdl:GetEntity()
			ent:SetSkin(1)
			if item.Data.Amount > 35 then
				ent:SetBodygroup(0, 1)
			else
				ent:SetBodygroup(0, 0)
			end

		end)
		:SetCountable(true)
		:SetMaxStack(50)