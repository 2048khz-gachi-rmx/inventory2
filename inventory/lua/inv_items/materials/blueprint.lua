--

local bucket = Inventory.BaseItemObjects.Generic("base_bp")
bucket 	:SetName("Empty Blueprint")
		
		:On("Paint", "PaintBlueprint", function(base, item, slot, w, h)
			local w, h = slot:GetSize()
			surface.SetDrawColor(color_white)
			render.PushFilterMin(TEXFILTER.ANISOTROPIC)
				local padx = w * 0.05
				local iw = w - padx*2
				local ih = h - h * 0.3
				surface.DrawMaterial("https://i.imgur.com/SpRAhWY.jpg", "crafting/baseblueprint.jpg", padx, h*0.2, iw, ih)
			render.PopFilterMin()
		end)
		--:SetModel("models/props_junk/MetalBucket01a.mdl")

		:SetCamPos( Vector(-73.6, -16.5, 40.6) )
		:SetLookAng( Angle(29.4, 12.7, 0.0) )
		:SetFOV( 15.6 )

		:SetCountable(true)
		:SetMaxStack(25)