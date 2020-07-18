local ITEM = {}
local iPan = Inventory.Panels

--[[
	To enable receiving items: Receiver "Item"
	Emits:
		"ItemHover" - when an item is hovered over this slot:
			1 - Panel : the slot that's being hovered
			2 - Item : the item that slot has

		"Drop" - when an item is dropped onto this slot
			1 - Panel : the slot that was dropped
			2 - Item : the item that slot has

		"DragStart" - when this item started to be dragged
			- global hook for this: "InventoryItemDragStart" (args: slot panel, item)

		"DragStop" - when this item stopped being dragged (dropped)
			1 - Panel(?) : panel or falsy value: on what this panel was dropped
			- global hook for this: "InventoryItemDragStop" (args: slot panel, item, receiver)

		"Think" - durr

		"Paint" - durr
			1 - Number: w
			2 - Number: h

		"PaintOver" - durr
			1 - Number: w
			2 - Number: h

		"Hover" - when the cursor enters the slot
		"Unhover" - when the cursor exits the slot

		"ItemInserted" - when a real item gets inserted into this slot
			1 - Number: slot
			2 - Item: the item that got inserted

		"ItemTakenOut" - when a real item is taken out of the slot
			1 - Item: the item that got pulled out

		"FakeItem" - when a fake item is inserted into this slot

		"DragHoverEnd"

]]

local function BestGuess(_, mdl, ...) --taken from BestGuessLayout

	local ent = mdl:GetEntity()
	local item = mdl.Item

	local pos = ent:GetPos()
	local ang = ent:GetAngles()

	local tab = PositionSpawnIcon( ent, pos, true )

	ent:SetAngles( ang )

	if ( tab ) then
		local orig = tab.origin
		local pos = item:GetCamPos()

		if pos then
			orig:Set(pos)
		end

		mdl:SetCamPos( orig )
		mdl:SetFOV( item:GetFOV() or tab.fov )
		mdl:SetLookAng( item:GetLookAng() or tab.angles )

	end

	mdl:SetColor(item:GetModelColor() or color_white)
	mdl.Spin = item:GetShouldSpin()
end

function ItemFrameUpdate(inv, pnl, it)
	if not pnl.Item or it.ItemName ~= pnl.Item.ItemName then return end
	pnl:Emit("BaseItemUpdate", it)
end

function ITEM:DetourStuff() --eh
	local a = self.DragHoverEnd

	function self.DragHoverEnd(...)
		a(...)
		self:Emit("DragHoverEnd")
	end

end

function ITEM:TrackChanges(inv, slot)
	self:GetInventory():On("Change", self, function()
		if inv:GetItemInSlot(slot) ~= self:GetItem() then
			self:SetItem(inv:GetItemInSlot(slot))
		end
	end)
end

function ITEM:Init()
	self:SetSize(iPan.SlotSize, iPan.SlotSize)
	self:SetText("")
	self:SetEnabled(false)

	self:Droppable("Item")
	self:SetCursor("arrow") --"none" causes flicker wtf
	self.DropFrac = 0

	self:Receiver("Item", function(self, tbl, drop)

		if not drop then
			self.DropHovered = true
			self:Emit("ItemHover", tbl[1], tbl[1].Item)
			return
		end

		self.DropHovered = false

		self:Emit("Drop", tbl[1], tbl[1].Item)
	end)

	self:On("DragHoverEnd", "DropHover", function()
		self.DropHovered = false
	end)

	self:On("Think", "DropHover", function(self)
		self:To("DropFrac", self.DropHovered and 1 or 0, self.DropHovered and 0.06 or 0.2, 0, 0.3)
	end)

	self:On("Drop", "ItemDrop", self.OnItemDrop)

	self:On("ItemInserted", "Alpha", function(self, slot, item)
		self:SetAlpha(255)
		self.TransparentModel = false
	end)

	self:On("FakeItem", "Alpha", function(self)
		self:SetAlpha(120)
		self.TransparentModel = true
	end)

	self.Rounding = 4

	self.BorderColor = Colors.LightGray:Copy()

	self:DetourStuff()
end

ChainAccessor(ITEM, "Slot", "Slot")

function ITEM:OnDragStart()
	self:Emit("DragStart")
	hook.Run("InventoryItemDragStart", self, self:GetItem(true))
end

function ITEM:OnDragStop()
	local rec = dragndrop.m_Receiver

	self:Emit("DragStop", rec)

	hook.Run("InventoryItemDragStop", self, self:GetItem(true), rec)
end

function ITEM:OnItemDrop(slot, it)

end

function ITEM:Think()
	self:Emit("Think")
end

function ITEM:OnCursorEntered()
	self:Emit("Hover")

	local it = self:GetItem(true)
	if not it then return end

	local cl = (IsValid(self.Cloud) and self.Cloud) or vgui.Create("ItemCloud", self)
	cl:Popup()
	cl:SetSize(self:GetSize())
	cl.ToY = -8

	local existed = self.Cloud == cl

	cl:SetRelPos(self:GetWide() / 2, 0)

	if not existed then
		cl:SetItem(it)
	end

	self.Cloud = cl
end

function ITEM:OnCursorExited()
	self:Emit("Unhover")

	local cl = IsValid(self.Cloud) and self.Cloud
	if not cl then return end

	cl:Popup(false)
end

function ITEM:OpenOptions()
	local it = self:GetItem(true)
	if not it then return end --e?

	local mn = vgui.Create("FMenu")
	mn:SetPos(gui.MouseX() - 8, gui.MouseY() + 1)
	mn:MoveBy(8, 0, 0.3, 0, 0.4)
	mn:PopIn()
	mn:Open()
	mn.WOverride = 200

	hook.Run("InventoryGetOptions", it, mn)
end

function ITEM:CreateModelPanel(it)
	if IsValid(self.ModelPanel) and it:GetModel() then
		self.ModelPanel:SetModel(it:GetModel())
		self.ModelPanel.Item = it

		BestGuess(nil, self.ModelPanel)
		return
	end

	if not IsValid(self.ModelPanel) and it:GetModel() then
		local mdl = vgui.Create("DModelPanel", self)
		mdl.Item = it

		mdl:SetMouseInputEnabled(false)
		mdl:SetSize(self:GetWide() - self.Rounding*2, self:GetTall())
		mdl:SetPos(self.Rounding, self.Rounding)
		mdl:SetModel(it:GetModel())
		mdl.Spin = true

		local pnt = mdl.Paint

		function mdl.Paint(me, w, h)

			if self.PaintingDragging or self.TransparentModel then
				render.OverrideAlphaWriteEnable( true, false )
				render.OverrideBlend(true, BLEND_SRC_COLOR, BLEND_ZERO, BLENDFUNC_MAX, 0, 0, 5)
			end

			pnt(me, w, h)

			if self.PaintingDragging or self.TransparentModel then
				render.OverrideBlend(false)
				render.OverrideAlphaWriteEnable( false )
			end

		end

		local spin = mdl.LayoutEntity
		function mdl:LayoutEntity(...)
			if not self.Spin then return end
			spin(self, ...)
		end

		self:On("BaseItemUpdate", mdl, BestGuess, mdl)
		BestGuess(_, mdl)
		self.ModelPanel = mdl
	end
end

function ITEM:SetInventoryFrame(it)
	self.InventoryFrame = it
	self.Inventory = it:GetInventory()

	local mf = it:GetMainFrame()

	if mf then self:SetSize(mf.SlotSize, mf.SlotSize) end
end

function ITEM:GetInventory()
	return self.Inventory
end

function ITEM:GetInventoryFrame()
	return self.InventoryFrame
end

function ITEM:SetItem(it)

	self:SetEnabled(Either(it, true, false))
	if self.FakeItem then self:SetFakeItem(nil) end

	if it then

		self.BorderColor = it.BorderColor and it.BorderColor:Copy() or Colors.LightGray
		self.FakeBorderColor = nil

		self.Item = it
		self:SetCursor("hand")

		self:Emit("ItemInserted", it:GetSlot(), it)

		Inventory:On("BaseItemDefined", self, ItemFrameUpdate, self)

		self:CreateModelPanel(it)

		self.Item:GetBaseItem():Emit("SetInSlot", self.Item, self, self.ModelPanel)

		--self:Emit("Item", it, true)

	elseif self.Item then --nilling the existing item
		self:Emit("ItemTakenOut", self.Item)
		self:SetCursor("arrow")

		self.Item = nil

		Inventory:RemoveListener("BaseItemDefined", self)

		if self.ModelPanel then
			self.ModelPanel:Remove()
			self.ModelPanel = nil
		end
	end

end


function ITEM:GetItem(real)
	return self.Item or (not real and self.FakeItem), (self.FakeItem ~= nil)
end

function ITEM:SetFakeItem(it)
	self.FakeItem = it
	if it ~= nil then
		self:Emit("FakeItem", it)
		self:CreateModelPanel(it)
	else
		if not self.Item then
			self.ModelPanel:Remove()
		end
	end
end

function ITEM:PrePaint()
end
function ITEM:PostPaint()
end

local hovCol = Color(130, 130, 130)

function ITEM:MaskHoverGrad(w, h)
	draw.RoundedPolyBox(self.Rounding - 2, 0, 0, w, h, color_black)
	surface.SetDrawColor(self.HoverGradientColor or hovCol) --sets the color for the gradient border
end

function ITEM:DrawBorder(w, h, col)
	local rnd = self.Rounding
	draw.RoundedBox(rnd, 0, 0, w, h, col)
	self:Emit("DrawBorder", w, h, col)
end

local emptyCol = Color(30, 30, 30)

function Inventory.Panels.ItemDraw(self, w, h)
	local rnd = self.Rounding

	local it = self.Item or self.FakeItem

	if it then

		local base = it:GetBaseItem()

		self.FakeBorderColor = self.FakeBorderColor or self.BorderColor:Copy()

		local col = self.FakeBorderColor
		local realcol = self.BorderColor
		local ch, cs, cv = ColorToHSV(realcol)

		self:To("BorderLight", self:IsHovered() and 1 or 0, 0.2, 0, 0.2)

		local add_val = self.BorderLight or 0

		draw.ColorModHSV(col, ch, cs, cv + add_val / 15)

		--print(cv + add_val / 10, col)
		self:DrawBorder(w, h, col) --draw.RoundedBox(rnd, 0, 0, w, h, col)
		draw.RoundedBox(rnd, 2, 2, w-4, h-4, self.Color or Colors.Gray)

		base:Emit("Paint", self.Item, self, self.ModelPanel)
	else
		local x, y, w, h = 0, 0, w, h

		if self.Border then
			self:DrawBorder(w, h, self.Border.col or emptyCol) --`draw.RoundedBox(rnd, 0, 0, w, h, self.Border.col or emptyCol)
			x, y = self.Border.w or 2, self.Border.h or 2
			w, h = w - x*2, h - y*2
		end

		draw.RoundedBox(rnd, x, y, w, h, self.EmptyColor or emptyCol)
	end

	if self.DropFrac > 0 then
		local f = self.DropFrac
		local sz = math.Round(f*3)
		--self.MaskHoverGrad(self, w, h)
		draw.Masked(self.MaskHoverGrad, self.DrawGradientBorder, nil, nil, self, w, h, sz, sz)
	end
end

function ITEM:Draw(w, h)
	Inventory.Panels.ItemDraw(self, w, h)

	--[[if self.Item then
		local it = self.Item
		local name = it:GetName()
		local wrap = name:WordWrap2(w - 4, "OS14")
		draw.RoundedBox(8, 0, 0, w, h, Colors.Gray)

		surface.SetTextColor(color_white)

		for s, line in eachNewline(wrap) do
			local tw = surface.GetTextSize(s) --surface.DrawNewlined(wrap, w/2, 2)

			surface.SetTextPos(w/2 - tw/2, 2 + (line - 1) * 14)
			surface.DrawText(s)
		end

	end]]

end

function ITEM:DoClick()
	print("e")
end

function ITEM:DoRightClick()
	self:OpenOptions()
end

function ITEM:Paint(w, h)
	self:PrePaint(w, h)
	self:Draw(w, h)
	self:PostPaint(w, h)
	self:Emit("Paint", w, h)
end

function ITEM:GetAmount()
	return (self.AmountOverride or self:GetItem():GetAmount())
end

local amtCol = Color(120, 120, 120)

function ITEM:PaintOver(w, h)
	local it = self.Item or self.FakeItem

	if it then
		draw.SimpleText(it:GetUID(), "OSB24", w/2, 0, Colors.DarkerRed, 1, 5)

		if it:GetCountable() then
			local amt = self:GetAmount()
			if amt then
				draw.SimpleText("x" .. amt, "MR18", w - 4, h, amtCol, 2, 4)
			end
		end

	end

	self:Emit("PaintOver", w, h)
end

ChainAccessor(ITEM, "MainFrame", "MainFrame")

vgui.Register("ItemFrame", ITEM, "DButton")