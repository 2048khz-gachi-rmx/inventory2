--
local bucket = Inventory.BaseItemObjects.Generic("bucket")
bucket 	:SetName("THE CUM BUCKET")
		:SetModel("models/props_junk/MetalBucket01a.mdl")

		:SetCamPos( Vector(-73.6, -16.5, 40.6) )
		:SetLookAng( Angle(29.4, 12.7, 0.0) )
		:SetFOV( 15.6 )

		:NetworkVar("Color", "Color")
		:On("SetInSlot", function(base, item, ipnl, imdl)
			imdl:SetColor(item.Data.Color or color_white)
		end)
		:SetCountable(true)
		:SetMaxStack(10)