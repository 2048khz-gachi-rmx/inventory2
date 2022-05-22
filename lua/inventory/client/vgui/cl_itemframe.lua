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
	inv:On("Change", self, function(...)
		if inv:GetItemInSlot(slot) ~= self:GetItem(true) then
			self:SetItem(inv:GetItemInSlot(slot))
		end
	end)
end

function ITEM:BindInventory(inv, slot)
	self:SetSlot(slot)
	self:SetInventory(inv)

	self:TrackChanges(inv, slot)

	if inv.Slots[slot] then
		self:SetItem(inv.Slots[slot])
	end
end

function ITEM:DoFastAction(why)
	self:Emit("FastAction", why)
end

function ITEM:DoDoubleClick()
	local ret = self:Emit("DoubleClick", self:GetSlot(), self:GetItem())
	if ret ~= nil then return end

	self:DoFastAction("double")
end

function ITEM:DoClick()
	local ret = self:Emit("Click", self:GetSlot(), self:GetItem())
	if ret ~= nil then return end

	if input.IsControlDown() then
		self:DoFastAction("ctrl")
	end
end


function ITEM:Init()
	self:SetSize(iPan.SlotSize, iPan.SlotSize)
	self:SetText("")
	self:SetEnabled(false)
	--self:SetDoubleClickingEnabled(false)

	self:Droppable("Item")
	self:SetCursor("arrow") --"none" causes flicker wtf
	self.DropFrac = 0
	self.Highlighted = true

	self:Receiver("Item", function(self, tbl, drop)
		if self.DropDisabled then return end
	
		local itm = tbl[1]:GetItem()
		if not itm then return end

		if not drop then
			self.DropHovered = true
			self:Emit("ItemHover", tbl[1], tbl[1].Item)
			return
		end

		self.DropHovered = false

		self:OnItemDrop(tbl[1], tbl[1].Item)
		self:Emit("Drop", tbl[1], tbl[1].Item)
	end)

	self:On("DragHoverEnd", "DropHover", function()
		self.DropHovered = false
	end)

	self:On("ItemInserted", "Alpha", function(self, slot, item)
		if self.TransparentModel then
			self:AlphaTo(255, 0.3, 0, 0.3)
			self.TransparentModel = false
		end
	end)

	self.Rounding = 4

	self.BorderColor = Colors.LightGray:Copy()

	self:DetourStuff()
end

ChainAccessor(ITEM, "Slot", "Slot")

function ITEM:OnInventoryUpdated()
	if self:GetItem() then
		self:GetItem():GetBaseItem():Emit("UpdatePanel", self:GetItem(), self, self.ModelPanel)
	end
end

function ITEM:OnMousePressed(c)
	vgui.GetControlTable("DButton").OnMousePressed(self, c)
	if c == MOUSE_MIDDLE then
		self.IsWheelHeld = true
	end
end

function ITEM:OnMouseReleased(c)
	vgui.GetControlTable("DButton").OnMouseReleased(self, c)

	timer.Simple(0, function()
		if not IsValid(self) then return end -- wtf lol
	
		-- let dragndrop run first
		self.IsWheelHeld = false
	end)
end

function ITEM:OnDragStart()
	if self:Emit("CanDrag") == false then dragndrop.Clear() return end
	if not self:GetItem(true) then return end

	self:Emit("DragStart")
	hook.Run("InventoryItemDragStart", self, self:GetItem(true))
end

function ITEM:OnDragStop()
	local rec = dragndrop.m_Receiver

	local itm = self:GetItem(true)

	self:Emit("DragStop", rec)
	hook.Run("InventoryItemDragStop", self, itm, rec)
end

function ITEM:OnItemDrop(slot, it)

end

function ITEM:Think()
	self:To("DropFrac", self.DropHovered and 1 or 0, self.DropHovered and 0.06 or 0.2, 0, 0.3)
	self:Emit("Think")
end

function ITEM:OnCursorEntered()
	self:Emit("Hover")

	local it = self:GetItem(true)
	if not it then return end

	hook.Run("InventoryItemHovered", self, it)

	local cl = (IsValid(self.Cloud) and self.Cloud) or vgui.Create("ItemCloud", self)
	cl:Popup()
	cl:SetSize(self:GetSize())
	cl.ToY = -8

	local existed = self.Cloud == cl

	cl:SetRelPos(self:GetWide() / 2, 0)

	if not existed then
		cl:SetItemFrame(self)
	end

	self.Cloud = cl
end

function ITEM:OnCursorExited()
	self:Emit("Unhover")

	hook.Run("InventoryItemUnhovered", self, self:GetItem(true))

	local cl = IsValid(self.Cloud) and self.Cloud
	if not cl then return end

	cl:Popup(false)
end

function ITEM:OpenOptions()
	local it = self:GetItem(true)
	if not it then  return end --e?

	local mn = vgui.Create("FMenu")
	mn:PopIn(0.05)

	mn.WOverride = 150

	hook.Run("InventoryGetOptions", it, mn)
	it:Emit("GenerateOptions", mn)
	it:GetBase():Emit("GenerateOptions", mn)

	local meta = Inventory.Util.GetMeta(it:GetItemID())
	if meta and meta.GenerateOptions then
		meta.GenerateOptions(it, mn)
	end

	mn:Open()
	mn:InvalidateLayout(true)

	local toX, toY = self:LocalToScreen(self:GetWide() + 4, self:GetTall() / 2 - mn:GetTall() / 2)

	mn:SetPos(toX - 16, toY)
	mn:MoveTo(toX, toY, 0.1, 0, 0.3)
end

function ITEM:CreateModelPanel(it)
	if IsValid(self.ModelPanel) then

		if it:GetModel() then
			self.ModelPanel:SetModel(it:GetModel())
			self.ModelPanel.Item = it

			if IsValid(self.ModelPanel:GetEntity()) then
				it:GetBaseItem():Emit("UpdateModel", it, self.ModelPanel:GetEntity(), true)
			end

			it:GetBaseItem():Emit("UpdatePanel", it, self, self.ModelPanel)

			BestGuess(nil, self.ModelPanel)
		else
			self.ModelPanel:Remove()
			self.ModelPanel = nil
		end

		return
	end

	if not it:GetModel() then return end

	local mdl = vgui.Create("DModelPanel", self)
	mdl.Item = it

	mdl:SetMouseInputEnabled(false)
	mdl:SetSize(self:GetWide() - self.Rounding*2, self:GetTall())
	mdl:SetPos(self.Rounding, self.Rounding)
	mdl:SetModel(it:GetModel())
	mdl.Spin = true

	local pnt = mdl.Paint

	function mdl.Paint(me, w, h)

		--[[if self.PaintingDragging or self.TransparentModel then
			render.OverrideAlphaWriteEnable( true, false )
			render.SetWriteDepthToDestAlpha( false )
			render.OverrideBlend(true, BLEND_SRC_COLOR, BLEND_SRC_ALPHA, BLENDFUNC_MIN, 0, 0, 5)
		end]]

		draw.EnableFilters()
		pnt(me, w, h)
		draw.DisableFilters()
		--[[if self.PaintingDragging or self.TransparentModel then
			render.OverrideBlend(false)
			render.OverrideAlphaWriteEnable( false )
			render.SetWriteDepthToDestAlpha( true )
		end]]

	end

	local spin = mdl.LayoutEntity
	function mdl:LayoutEntity(...)
		if not self.Spin then return end
		spin(self, ...)
	end

	self:On("BaseItemUpdate", mdl, BestGuess, mdl)
	BestGuess(_, mdl)
	self.ModelPanel = mdl

	if IsValid(self.ModelPanel:GetEntity()) then
		it:GetBaseItem():Emit("UpdateModel", it, self.ModelPanel:GetEntity(), true)
	end

	it:GetBaseItem():Emit("UpdatePanel", it, self, self.ModelPanel)
end

function ITEM:SetInventoryPanel(it)
	self.InventoryPanel = it
	self.Inventory = it:GetInventory()

	local mf = it:GetMainFrame()

	if mf then self:SetSize(mf.SlotSize, mf.SlotSize) end
end

ChainAccessor(ITEM, "Inventory", "Inventory", true)
ChainAccessor(ITEM, "InventoryPanel", "InventoryPanel", true)

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

		--self:Emit("Item", it, true)
		self:OnInventoryUpdated()
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
	local ret = self.Item or (not real and self.FakeItem) or nil
	return ret, ret and ret == self.FakeItem
end

function ITEM:SetFakeItem(it)
	self.FakeItem = it
	if it ~= nil then
		self:SetAlpha(120)
		self.TransparentModel = true
		self:CreateModelPanel(it)
		self:Emit("FakeItem", it)
	else
		self:AlphaTo(255, 0.3, 0, 0.3)
		self.TransparentModel = false
		self:Emit("FakeItemTakenOut", it)
		if not self.Item and self.ModelPanel then
			self.ModelPanel:Remove()
		end
	end
end

function ITEM:PrePaint()
end
function ITEM:PostPaint()
end

function ITEM:Dehighlight()
	self.Highlighted = false
end

function ITEM:Highlight()
	self.Highlighted = true
end

local hovCol = Color(130, 130, 130)

function ITEM:MaskHoverGrad(w, h)
	draw.RoundedPolyBox(self.Rounding - 2, 0, 0, w, h, color_black)
	surface.SetDrawColor(self.HoverGradientColor or hovCol) --sets the color for the gradient border (since that's a meta function, not ours)
end

function ITEM:DrawBorder(w, h, col)
	if self:Emit("DrawBorder", w, h, col) == false then return end
	local rnd = self.Rounding
	draw.RoundedBox(rnd, 0, 0, w, h, col)
	self:Emit("PostDrawBorder", w, h, col)
end

local emptyCol = Color(26, 26, 26)
local emptyGradCol = Color(30, 30, 30)
--local emptyInCol = Color(26, 26, 26)

function Inventory.Panels.ItemDraw(self, w, h)
	local rnd = self.Rounding

	local it = self.Item or self.FakeItem

	if it then
		local base = it:GetBaseItem()

		--self.FakeBorderColor = self.FakeBorderColor or self.BorderColor:Copy() -- copy the color so we dont modify the original, and use it for drawing the border

		local drawcol = self:CopiedColor(self.Color or Colors.Gray, "draw")
		local bordcol = self:CopiedColor(self.BorderColor, "border")

		--local col = self.FakeBorderColor
		--local realcol = self.BorderColor

		self:To("BorderLight", self:IsHovered() and 1 or 0, 0.2, 0, 0.2)
		local add_val = self.BorderLight or 0


		self:To("DrawColDim", self.Highlighted and 0 or 1, 0.3, 0, 0.3)

		local bh, bs, bv = ColorToHSV(self.BorderColor)
		local ch, cs, cv = ColorToHSV(self.Color or Colors.Gray)
		local dim = self.DrawColDim or 0

		bordcol:SetHSV(bh, bs, bv + add_val / 15 - cv * dim * 0.3)
		drawcol:SetHSV(ch, cs, cv - cv * dim * 0.3)


		self:DrawBorder(w, h, bordcol)
		local bSz = 2
		draw.RoundedBox(rnd, bSz, bSz, w - bSz * 2, h - bSz * 2, drawcol)

		local preMult = surface.GetAlphaMultiplier()

		surface.SetAlphaMultiplier(preMult - dim * 0.6 * preMult)
			base:Emit("Paint", self:GetItem(), self, self.ModelPanel)
		surface.SetAlphaMultiplier(preMult)
	else
		local x, y, w, h = 0, 0, w, h

		if self.Border then
			self:DrawBorder(w, h, self.Border.col or emptyCol) --`draw.RoundedBox(rnd, 0, 0, w, h, self.Border.col or emptyCol)
			x, y = self.Border.w or 2, self.Border.h or 2
			w, h = w - x*2, h - y*2
		end

		local bSz = 2

		draw.RoundedBox(rnd, x, y, w, h, self.EmptyColor or emptyCol)

		--draw.RoundedBox(rnd, x, y, w, h, self.EmptyColor or emptyCol)
		--draw.RoundedBox(rnd, x + bSz, y + bSz, w - bSz * 2, h - bSz * 2, self.EmptyColor or emptyInCol)

		surface.SetMaterial(MoarPanelsMats.gd)
		surface.SetDrawColor(emptyGradCol)
		local gH = math.ceil(h)
		surface.DrawTexturedRectUV(bSz, y + h - bSz - gH, w - bSz * 2, gH, 0, 0, 1, 1)
	end

	if self.DropFrac > 0 then
		local f = self.DropFrac
		local sz = math.Round(f * 3)
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
local boxCol = Color(35, 35, 35, 220)

local initA = boxCol.a
local initAA = amtCol.a

local dev = GetConVar("developer")
function ITEM:PaintOver(w, h)
	local it = self.Item or self.FakeItem

	if it then
		if dev:GetInt() > 0 then
			draw.SimpleText(it:GetNWID(), "OS16", w/2, 0, Colors.DarkerRed, 1, 5)
		end

		if it:GetCountable() then
			local dim = self.DrawColDim or 0

			boxCol.a = initA * (1 - dim) * 0.3 + initA * 0.7
			amtCol.a = initAA * (1 - dim) * 0.3 + initAA * 0.7

			local amt = self:GetAmount()
			local amtFont = "MR18"
			if amt then
				surface.SetFont(amtFont)
				local tw, th = surface.GetTextSize("x" .. amt)

				local tpadx = 2
				local tpady = 2

				draw.RoundedBoxEx(self.Rounding, w - tpadx*3 - tw, h - th, tw + tpadx*2, th - tpady, boxCol, true)
				draw.SimpleText("x" .. amt, amtFont, w - tpadx*2, h, amtCol, 2, 4)
			end
		end

	end

	self:Emit("PaintOver", w, h)
end

ChainAccessor(ITEM, "MainFrame", "MainFrame")

vgui.Register("ItemFrame", ITEM, "DButton")