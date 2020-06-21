local PANEL = {}

function PANEL:Init()
	local mdl = vgui.Create("DModelPanel", self)
	mdl:Dock(FILL)
	mdl:DockMargin(12, 8, 12, 8)
	mdl:SetModel(LocalPlayer():GetModel())
	mdl:SetFOV(40)

	local p = mdl.Paint
	local col = Color(40, 40, 40)
	function mdl:Paint(w, h)
		draw.RoundedBox(16, 0, 0, w, h, col)
		p(self, w, h)
	end
	self.ModelPanel = mdl

	self.Slots = {}
	self.Shadow = {}

	self:SetCloseable(false, true)

	self:On("GetMainFrame", self.SizeToMain)

end

function PANEL:SetMainFrame(p)
	self.MainFrame = p
	self:Emit("GetMainFrame", p)
end

function PANEL:GetMainFrame()
	return self.MainFrame
end

function PANEL:SizeToMain(main)
	self:SetSize(math.min(main:GetWide() * 0.5, 450), math.max(450, main:GetTall()))
end

function PANEL:Think()
	if dragndrop.IsDragging() then --motherfuckin dragndrop
		self.IsWheelHeld = input.IsMouseDown(MOUSE_MIDDLE)
	end
end

function PANEL:AddItemSlot()

end

function PANEL:GetItems()
	return self.Items
end

function PANEL:GetSlots()

end


function PANEL:PrePaint()
end
function PANEL:PostPaint()
end


vgui.Register("InventoryCharacter", PANEL, "FFrame")