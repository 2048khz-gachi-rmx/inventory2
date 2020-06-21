local ITEM = {}
local iPan = Inventory.Panels

local function BestGuess(_, mdl, ...) --taken from BestGuessLayout

	local ent = mdl:GetEntity()
	local item = mdl.Item

	local pos = ent:GetPos()
	local ang = ent:GetAngles()

	local tab = PositionSpawnIcon( ent, pos, true )

	ent:SetAngles( ang )

	if ( tab ) then
		mdl:SetCamPos( tab.origin + (item:GetCamOffset() or 0) )
		mdl:SetFOV( item:GetFOV() or tab.fov )
		mdl:SetLookAng( item:GetLookAng() or tab.angles )
	end
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

	self.Rounding = 4

	self:DetourStuff()
end

ChainAccessor(ITEM, "Slot", "Slot")

function ITEM:OnItemDrop(slot, it)

end

function ITEM:Think()
	self:Emit("Think")
end

function ITEM:OnCursorEntered()
	self:Emit("Hover")
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
	if not IsValid(self.ModelPanel) and it:GetModel() then
		local mdl = vgui.Create("DModelPanel", self)
		mdl.Item = it

		mdl:SetMouseInputEnabled(false)
		mdl:SetSize(self:GetWide() - self.Rounding*2, self:GetTall())
		mdl:SetPos(self.Rounding, self.Rounding)
		mdl:SetModel(it:GetModel())
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

		self:On("BaseItemUpdate", mdl, BestGuess, mdl)
		BestGuess(_, mdl)
		self.ModelPanel = mdl
	end
end

function ITEM:SetItem(it)

	self:SetEnabled(Either(it, true, false))
	if self.FakeItem then self:SetFakeItem(nil) end
	if it then
		self.Item = it
		self:SetCursor("hand")

		self:Emit("ItemInserted", it:GetSlot(), it)

		Inventory:On("BaseItemDefined", self, ItemFrameUpdate, self)

		self:CreateModelPanel(it)

		self.Item:GetBaseItem():Emit("SetInSlot", self.Item, self, self.ModelPanel)
	elseif self.Item then
		self:Emit("ItemTakenOut", self.Item)
		self:SetCursor("arrow")

		self.Item = nil

		Inventory:RemoveListener("BaseItemDefined", self)
		self.ModelPanel:Remove()
		self.ModelPanel = nil
	end

end


function ITEM:GetItem(real)
	return self.Item or (not real and self.FakeItem), (self.FakeItem ~= nil)
end

function ITEM:SetFakeItem(it)
	self.FakeItem = it
	if it ~= nil then
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
	surface.SetDrawColor(hovCol) --sets the color for the gradient border
end

local emptyCol = Color(30, 30, 30)

function Inventory.Panels.ItemDraw(self, w, h)
	local rnd = self.Rounding

	local it = self.Item or self.FakeItem
	if self.FakeItem then
		self:SetAlpha(120)
		self.TransparentModel = true
	else
		self:SetAlpha(255)
		self.TransparentModel = false
	end

	if it then
		local base = it:GetBaseItem()

		draw.RoundedBox(rnd, 0, 0, w, h, Colors.LightGray)
		draw.RoundedBox(rnd, 2, 2, w-4, h-4, Colors.Gray)

		base:Emit("Paint", self.Item, self, self.ModelPanel)
	else
		draw.RoundedBox(rnd, 0, 0, w, h, emptyCol)
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