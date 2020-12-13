--

local function Dehighlight(b)

	if b == nil or b then
		

	else
		for k, slot in ipairs(inv:GetSlots()) do
			slot:Highlight()
		end
	end

end

function ENT:CraftFromBlueprintMenu(open, main)
	local inv = main.Inventory
	local cur = inv:GetInventoryPanel()

	if not open then
		local canv = main:HideAutoCanvas("bp")
		canv.Hidden = true
		canv:SetZPos(999)

		for k, slot in ipairs(inv:GetSlots()) do
			slot:Highlight()
		end

		return
	end

	local canvas, new = main:ShowAutoCanvas("bp", nil, 0.1, 0.2)
	canvas.Hidden = false
	canvas:SetZPos(0)
	canvas:PopIn(0.1, 0.2)

	if new then main:PositionPanel(canvas) else return end

	for k, slot in ipairs(inv:GetSlots()) do

		slot:On("Think", canvas, function()
			if not canvas:IsVisible() or canvas.Hidden then return end

			local it = slot:GetItem()
			if not it then return end

			if not it.IsBlueprint then
				slot:Dehighlight()
			else
				slot:Highlight()
			end
		end)

	end


	local pnl = vgui.Create("InvisPanel", canvas)
	pnl:SetSize(canvas:GetWide() * 0.95, canvas:GetTall() * 0.95)
	pnl:Center()

	local dragBP = false
	local isHov = false

	hook.Add("InventoryItemDragStart", canvas, function(_, slot, item)
		if item.IsBlueprint then
			dragBP = item
		end
	end)

	hook.Add("InventoryItemDragStop", canvas, function(_, slot, item)
		if item.IsBlueprint then
			dragBP = false
		end
	end)

	local desCol = Color(10, 10, 10)
	local curCol = Color(10, 10, 10)

	function pnl:Paint(w, h)
		surface.SetDrawColor(Colors.DarkGray:Unpack())
		surface.DrawRect(0, 0, w, h)

		isHov = self:IsHovered()

		local fr = self.DragFrac or 0

		local r = 10 + (dragBP and 1 or 0) * (isHov and 50 or 30)
		local g = 10 + (dragBP and 1 or 0) * (isHov and 160 or 90)
		local b = r

		desCol:Set(r, g, b)
		self:LerpColor(curCol, desCol, 0.3, 0, 0.3)

		self:To("HovFrac", isHov and 1 or 0, 0.3, 0, 0.3)
		self:To("DragFrac", dragBP and 1 or 0, 0.3, 0, 0.3)

		if not isHov and fr > 0 then
			self:To("GradSz", 2, 0.3, 0, 0.3)
		else
			self:To("GradSz", 0, 0.3, 0, 0.3)
		end

		local sz = self.GradSz or 0
		surface.SetDrawColor(curCol:Unpack())
		self:DrawGradientBorder(w, h, 3 + sz, 3 + sz)
		

		local rgb = 255
		local a = 60 - self.DragFrac * 30


		if dragBP then
			a = a - self.HovFrac * 30
		else
			a = a + self.HovFrac * 60
		end

		surface.SetTextColor(rgb, rgb, rgb, a)
		draw.SimpleText2("AAA", "OS24", w/2, h/2, nil, 1, 1)
	end
end