include("shared.lua")

local me = {}
ENT.ContextInteractable = true

function ENT:Initialize()
	self:SHInit()
end

function ENT:DrawDisplay()

end


function ENT:InteractItem(item, slot)

end

function ENT:ContextInteractItem(item, slot)

end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()

end



function ENT:WithdrawItem(slot, to)
	local inv = self.OreInput

end

function ENT:QueueOre(slot, it, bulk)
	if not it then return end

	local nw = Inventory.Networking.Netstack()

		nw:WriteEntity(self)
		nw:WriteInventory(it:GetInventory())
		nw:WriteItem(it)
		nw:WriteBool(bulk and true or false)
		if not bulk then nw:WriteUInt(slot, 16) end

	nw:Send("OreRefinery")

	if bulk then
		local free = 0
		for i=1, self.MaxQueues do
			local slIt = self.OreInput.Slots[i]
			if not slIt then free = free + 1 end
		end

		it:SetAmount( math.max(it:GetAmount() - free, 0))
	else
		it:SetAmount(it:GetAmount() - 1)
	end
end

function ENT:CreateInputSlot(slot)
	local ent = self

	slot:SetSlot(slot.ID)

	slot:On("ItemHover", "OresOnly", function(slot, slot2, item)
		if not item:GetBase().IsOre then
			slot.HoverGradientColor = Colors.Red
		else
			slot.HoverGradientColor = Colors.Money
		end
	end)

	slot:On("Drop", "DropOre", function(slot, slot2, item)
		if not item:GetBase().IsOre or not item:GetInventory().IsBackpack then return false end
		ent:QueueOre(slot.ID, item)
	end)

	local col = Color(250, 110, 20)
	slot:On("DrawBorder", "DrawSmeltingProgress", function(self, w, h)

		local it = self.Item
		local base = it:GetBase()
		local refTime = base:GetSmeltTime()
		local start = ent.Status:Get(self:GetSlot(), 0)

		local fr = math.min((CurTime() - start) / refTime, 1)

		draw.RoundedBox(4, 0, h - fr*h, w, fr*h, col)
	end)

	slot.Inventory = self.OreInput
	slot:TrackChanges(slot.Inventory, slot.ID)

	if slot.Inventory.Slots[slot.ID] then
		slot:SetItem(slot.Inventory.Slots[slot.ID])
	end
end

function ENT:CreateOutputSlot(slot)
	local ent = self

	slot:SetSlot(slot.ID)

	slot:On("ItemHover", "OresOnly", function(slot, slot2, item)
		if item == slot:GetItem() then
			slot.HoverGradientColor = nil
		else
			slot.HoverGradientColor = Colors.Red
		end
	end)

	slot:On("Drop", "DropOre", function(slot, slot2, item)
		return false
	end)

	slot.Inventory = self.OreOutput

	slot:TrackChanges(slot.Inventory, slot.ID)

	if slot.Inventory.Slots[slot.ID] then
		slot:SetItem(slot.Inventory.Slots[slot.ID])
	end
end

function ENT:OnInventorySlotPickup(slot) 	--called for the actual inventory's slots when they get picked up
	local item = slot:GetItem()
end

function ENT:OnInventorySlotDrop(slot) 	--same but when it stops being dragged
	local item = slot:GetItem()
end

local slotSize = 64

local slotPadX = 8 --MINIMUM padding ; if there's less slots than a row can fit, it'll increase padding to compensate
local slotPadY = 8

function ENT:OnOpenRefine(ref, pnl)
	if IsValid(pnl) then pnl:PopInShow() return pnl end
	if not op then op = SysTime() end

	local ent = self

	local main = vgui.Create("Panel", ref)
	ref:PositionPanel(main)
	-- INPUT
	local p = vgui.Create("Panel", main)
	--p:Debug()

	p:SetTall(main:GetTall() * 0.7)
	p:SetWide(main:GetWide())

	local rows = {}

	local fitsOnRow = math.max(math.floor(p:GetWide() / (slotSize + slotPadX)), 1) -- don't worry i already infinite-loop'd myself 3 times on division-by-0
	local amtrows = math.ceil(self.MaxQueues / fitsOnRow)

	local slotW, slotH = slotSize + slotPadX, slotSize + slotPadY

	for i=1, amtrows do

		local t = {}
		rows[i] = t
								-- V means we can fit all slots 			V means we're the last row and we can fit more slots than there are left
		local amtSlots = (self.MaxQueues / fitsOnRow / i >= 1 and fitsOnRow) or self.MaxQueues % fitsOnRow

		local padlessW = amtSlots * slotSize
		local marginX = (p:GetWide() - padlessW) / (amtSlots + 1)
		local padX = marginX / 1.3
		local slotW = slotSize + padX
		t.amtSlots = amtSlots
		t.fullWidth = amtSlots * slotW - padX

		t.icY = p:GetTall() / 2 - (amtrows * slotH) / 2 + ((i-1) * slotH)
		t.icX = p:GetWide() / 2 - t.fullWidth / 2
		t.slotW = slotW
	end

	local slotID = 0

	for i, row in ipairs(rows) do

		local icX = row.icX

		for si=1, row.amtSlots do
			slotID = slotID + 1

			local slot = vgui.Create("ItemFrame", p)
			slot:SetSize(slotSize, slotSize)
			slot:SetPos(icX, row.icY)
			slot.ID = slotID
			self:CreateInputSlot(slot)

			icX = icX + row.slotW
		end
	end


	-- OUTPUT
	local out = vgui.Create("DHorizontalScroller", main)
	out:SetTall(main:GetTall() * 0.3)
	out:SetWide(main:GetWide())
	out.Y = main:GetTall() * 0.7

	function out:Paint(w, h)
		surface.SetDrawColor(40, 40, 40)
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(10, 10, 10)
		surface.SetMaterial(MoarPanelsMats.gu)
		surface.DrawTexturedRect(0, 0, w, 4)
	end

	--Output has only one row so its a bit simpler

	local totalW = (slotSize + slotPadX) * self.OutputSlots - slotPadX

	local icX = out:GetWide() / 2 - totalW / 2

	if totalW > out:GetWide() then
		icX = 8
	end

	for i=1, self.OutputSlots do
		local slot = vgui.Create("ItemFrame", out)
		slot:SetSize(slotSize, slotSize)
		slot:SetPos(icX, out:GetTall() / 2 - slotSize / 2)
		slot.ID = i

		self:CreateOutputSlot(slot)
		icX = icX + slotSize + slotPadX
	end

	local qAll = vgui.Create("InvisPanel", ref)
	ref:PositionPanel(qAll)
	qAll:SetMouseInputEnabled(false)
	Inventory.Panels.ListenForItem(qAll)

	qAll:On("Drop", function(self, slot, item)
		--[[for i=1, ent.MaxQueues do
			local it = ent.OreInput.Slots[i]
			if it then continue end

			if item:GetAmount() <= 0 then break end
		end]]

		ent:QueueOre(i, item, true)
	end)

	qAll.Frac = 0
	function qAll:Think()
		self.Ctrl = input.IsShiftDown()

		if self.Ctrl and self.Dragging then
			self:SetMouseInputEnabled(true)
		else
			self:SetMouseInputEnabled(false)
		end
	end

	local blk = color_black:Copy()
	local gray = Colors.DarkerGray:Copy()
	local wht = color_white:Copy()

	local tx = "Queue x%d %s"
	local str

	function qAll:Paint(w, h)
		if self.Ctrl and self.Dragging then
			self:To("Frac", 1, 0.3, 0, 0.3)
		else
			self:To("Frac", 0, 0.2, 0, 0.3)
		end

		local fr = self.Frac

		gray.a = fr * 230
		blk.a = fr * 250
		wht.a = fr * 255

		surface.SetDrawColor(gray:Unpack())
		surface.DrawRect(0, 0, w, h)

		surface.SetDrawColor(blk:Unpack())
		self:DrawGradientBorder(w, h, 4, 4)

		local it = self.Dragging

		if it then
			local free = ent.MaxQueues - table.Count(ent.OreInput.Items)
			str = tx:format(math.min(it:GetAmount(), free), it:GetName())
		end

		draw.SimpleText(str, "OSB36", w/2, h/2, wht, 1, 1)

	end

	hook.Add("InventoryItemDragStart", main, function(_, slot, slotitem)
		if not slotitem or not slotitem:GetBase().IsOre then return end
		qAll.Dragging = slotitem
	end)


	hook.Add("InventoryItemDragStop", main, function(_, slot, slotitem, rec)
		qAll.Dragging = false
	end)

	return main
end

function ENT:OnCloseRefine(ref)

end

function ENT:OpenMenu()
	if IsValid(self.Frame) then return end

	local inv = Inventory.Panels.CreateInventory(LocalPlayer().Inventory.Backpack, nil, {
		SlotSize = 64
	})

	--inv:SetTall(350)
	inv:CenterVertical()

	for k,v in pairs(inv:GetSlots()) do
		v:On("DragStart", "Refinery", function(...) self:OnInventorySlotPickup(...) end)
		v:On("DragStop", "Refinery", function(...) self:OnInventorySlotDrop(...) end)
	end

	local ref = vgui.Create("NavFrame")
	self.Frame = ref
	ref:SetSize(450, inv:GetTall())
	ref:MakePopup()
	ref:SetPos( ScrW() / 2 - (ref:GetWide() + 8 + inv:GetWide()) / 2,
				ScrH() / 2 - ref:GetTall() / 2)
	ref.Shadow = {}
	ref:SetRetractedSize(40)
	ref:SetExpandedSize(200)
	ref.BackgroundColor = Color(50, 50, 50)
	inv:Bond(ref)
	ref:Bond(inv)

	inv:MoveRightOf(ref, 8)

	local refTab = ref:AddTab("Refine ores", function(_, _, pnl) self:OnOpenRefine(ref, pnl) end, function() self:OnCloseRefine(ref) end)
	refTab:SetTall(60)
	refTab:Select(true)

end

net.Receive("OreRefinery", function()
	local ent = net.ReadEntity()
	local typ = net.ReadUInt(4)

	if typ == 0 then --open menu
		ent:OpenMenu()
	end
end)
