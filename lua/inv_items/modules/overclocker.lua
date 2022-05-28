local ovck = Inventory.BaseItemObjects.EntityModule:new("overclocker")

ovck 	:SetName("Overclocker")
		--:SetCompatible({"refinery"})
		:On("Paint", "PaintOverclocker", function(base, item, slot)
			local w, h = slot:GetSize()
			surface.SetDrawColor(color_white)
			render.PushFilterMin(TEXFILTER.ANISOTROPIC)
				local iw = w  * 0.8
				local ih = h - h * 0.2
				local sz = math.min(iw, ih)
				surface.DrawMaterial("https://i.imgur.com/6yXsv86.png", "overclock128.png", w/2 - sz/2, h/2 - sz/2, sz, sz)
			render.PopFilterMin()
		end)

		:SetCountable(false)