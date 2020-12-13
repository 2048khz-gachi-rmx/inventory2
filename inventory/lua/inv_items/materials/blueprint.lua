--

local basebp = Inventory.BaseItemObjects.Generic("base_bp")
basebp 	:SetName("Empty Blueprint")

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

		:SetCountable(true)
		:SetMaxStack(25)



local blueprint = Inventory.BaseItemObjects.Blueprint("blueprint")
blueprint 	:SetName("Blueprint -- you're not supposed to see this!")

		:On("Paint", "PaintBlueprint", function(base, item, slot, w, h)
			local w, h = slot:GetSize()
			surface.SetDrawColor(Colors.Red)
			render.PushFilterMin(TEXFILTER.ANISOTROPIC)
				local padx = w * 0.05
				local iw = w - padx*2
				local ih = h - h * 0.3
				surface.DrawMaterial("https://i.imgur.com/SpRAhWY.jpg", "crafting/baseblueprint.jpg", padx, h*0.2, iw, ih)
			render.PopFilterMin()
		end)