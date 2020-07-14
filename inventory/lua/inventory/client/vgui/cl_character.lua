local PANEL = {}

local textAreaHeight = 24 -- at the very top, says 'Character'

function PANEL:Init()

	self.Shadow = {}
	self:SetCloseable(false, true)

	local mdl = vgui.Create("DModelPanel", self)
	mdl:Dock(FILL)
	mdl:DockMargin(24, textAreaHeight + 8, 24, 8)
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
	self:CreateSlots()

	self:On("GetMainFrame", self.SizeToMain)

end

function PANEL:SetMainFrame(p)
	self.MainFrame = p
	self:Emit("GetMainFrame", p)
end

function PANEL:GetMainFrame()
	return self.MainFrame
end

local eqBtnSize = 68

function PANEL:SizeToMain(main)
	self:SetSize(math.min(main:GetWide() * 0.6, 450), math.max(450, main:GetTall()))
end

function PANEL:Think()

end

local function PaintSlotName(self, w, h)
	DisableClipping(true)
		draw.SimpleText(self.Name, "OS18", w/2, 0, color_white, 1, 4)
	DisableClipping(false)
end

function PANEL:PerformLayout(w, h)

	--area we shouldn't consider when centering vertically; consists of header and text area

	local nonArea = self.HeaderSize + textAreaHeight

	for k,v in ipairs(self.Slots) do
		local slot, name = v.Slot, v.Name
		local nwid, side = v.ID, v.Side

		local y = v.YFrac 	-- this is a 0-1, which is the middle of the button on the panel
							-- (e.g. 0.4 = 40%, so the button's middle should be at 40% of the panel height)

		local x = (side == LEFT and 4) or w - eqBtnSize - 4
		y = (h - nonArea) * y - (eqBtnSize / 2) + nonArea

		v:SetPos(x, y)
	end

end

local function canEquip(btn, item)
	return item:GetEquippable() and item:GetEquipSlot() == btn.Slot
end

							-- V bruh
function PANEL.HoverItem(slot, self, itslot, item)

end

							-- V bruh
function PANEL.EquipItem(slot, self, itemfr, item)
	if not canEquip(slot, item) then return end

	local ns = Inventory.Networking.Netstack()
	ns:WriteInventory(item:GetInventory())
	ns:WriteItem(item)
	ns:WriteUInt(slot.ID, 8)
	Inventory.Networking.PerformAction(INV_ACTION_EQUIP, ns)

	slot:SetItem(item)
	local inv = item:GetInventory()

	inv:CrossInventoryMove(item, self:GetInventory(), slot.ID)
	--[[inv:RemoveItem(item)
	self:GetInventory():AddItem(item)
	item:SetSlot(slot.ID)]]
	itemfr:SetItem(nil)
end

function PANEL:HighlightFit(btn, itemfr, item)
	local can = canEquip(btn, item)
	if not can then
		btn.HoverGradientColor = Colors.DarkerRed
		btn:AlphaTo(120, 0.1, 0)
		return
	end

	btn.HoverGradientColor = Colors.Money
end

function PANEL:GetInventory()
	return LocalPlayer().Inventory.Character
end

function PANEL:DehighlightFit(btn, itemfr, item)
	btn.HoverGradientColor = nil
	btn:AlphaTo(255, 0.1, 0)
end


--takes a table of slot-tables from Inventory.EquipmentSlots

local function CreateSlots(self, tbl)
	local frac = 1 / #tbl
	local char = LocalPlayer().Inventory.Character

	local curryHighlight = function(btn, ...)
		self:HighlightFit(btn, ...)
	end

	local curryDehighlight = function(btn, ...)
		self:DehighlightFit(btn, ...)
	end

	for k,v in ipairs(tbl) do
		local slot, name = v.slot, v.name
		local nwid = v.id

		local side = v.side

		local btn = vgui.Create("ItemFrame", self)
		btn:SetSize(eqBtnSize, eqBtnSize)
		btn:SetInventoryFrame(self)
		btn.Rounding = 4
		btn.Border = {col = Colors.LightGray}
		btn.YFrac = frac * (k - 0.5)

		btn.Side = side
		btn.ID = nwid
		btn.Slot = slot
		btn.Name = name

		btn:On("Paint", "PaintSlotName", PaintSlotName)
		btn:On("Drop", "EquipItem", self.EquipItem, self)

		if char.Slots[nwid] then
			btn:SetItem(char.Slots[nwid])
		end
		hook.Add("InventoryItemDragStart", btn, curryHighlight)
		hook.Add("InventoryItemDragStop", btn, curryDehighlight)

		self.Slots[#self.Slots + 1] = btn
	end
end

function PANEL:CreateSlots()
	local slots = Inventory.EquipmentSlots
	local len = #slots

	local left, right = {}, {}

	for k,v in ipairs(slots) do
		if v.side == LEFT then left[#left + 1] = v
		elseif v.side == RIGHT then right[#right + 1] = v
		else errorf("Unrecognized Equipment button side: %q", v.side) end
	end

	-- when CreateSlots gets called, we don't have the correct height/width yet
	-- so calculate the Y of the buttons as a percentage, where it'll be the middle of the button

	CreateSlots(self, left)
	CreateSlots(self, right)
end


function PANEL:PrePaint()

end

function PANEL:PostPaint(w, h)

end


vgui.Register("InventoryCharacter", PANEL, "FFrame")