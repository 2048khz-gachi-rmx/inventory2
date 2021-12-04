--

local basebp = Inventory.BaseItemObjects.Generic("blank_bp")
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

		:On("PaintSprite", "PaintBlueprint", function(base, item, sz)
			surface.SetDrawColor(color_white)
			local nw, nh = Icons.BlankBlueprint:RatioSize(sz, sz)
			Icons.BlankBlueprint:Paint(sz / 2 - nw / 2, sz / 2 - nh / 2, nw, nh)
		end)

		:SetCountable(true)
		:SetMaxStack(100)



local blueprint = Inventory.BaseItemObjects.Blueprint("blueprint")
blueprint
	:SetName("Blueprint -- you're not supposed to see this!")
	:On("Paint", "PaintBlueprint", function(base, item, slot, w, h)
		local w, h = slot:GetSize()
		local _, fake = slot:GetItem()

		local padx = w * 0.05
		local iw = w - padx*2
		local ih = h - h * 0.3
		local x, y = padx, h*0.2
		item:PaintBlueprint(x, y, iw, ih, fake)
	end)

		--[[:On("Paint", "PaintBlueprint", function(base, item, slot, w, h)
			local w, h = slot:GetSize()
			surface.SetDrawColor(Colors.Red)
			render.PushFilterMin(TEXFILTER.ANISOTROPIC)
				local padx = w * 0.05
				local iw = w - padx*2
				local ih = h - h * 0.3
				surface.DrawMaterial("https://i.imgur.com/SpRAhWY.jpg", "crafting/baseblueprint.jpg", padx, h*0.2, iw, ih)
			render.PopFilterMin()
		end)]]