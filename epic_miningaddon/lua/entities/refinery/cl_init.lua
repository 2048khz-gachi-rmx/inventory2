include("shared.lua")

local me = {}
ENT.ContextInteractable = true

function ENT:Initialize()
	self.Inventory = {Inventory.Inventories.Entity:new(self), Inventory.Inventories.Entity:new(self)}

	self.OreInput = self.Inventory[1] --shortcuts
	self.OreInput.MaxItems = self.MaxQueues

	self.OreOutput = self.Inventory[2]
	self.OreOutput.MaxItems = 5
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

local slotSize = 64

local slotPadX = 8 --MINIMUM padding ; if there's less slots than a row can fit, it'll increase padding to compensate
local slotPadY = 8

function ENT:WithdrawItem(slot, to)
	local inv = self.OreInput
	--[[if not inv.Slots[slot] then errorf("How %s", slot) return end

	local nw = Inventory.Networking.Netstack()
		nw:WriteEntity(self)
		nw:WriteUInt(1, 4)
		nw:WriteUInt(slot, 16)
		nw:WriteUInt(to, 16)
	nw:Send("OreRefinery")]]

end

function ENT:CreateItemSlot(slot)
	slot:SetSlot(slot.ID)

	slot:On("ItemHover", "OresOnly", function(slot, slot2, item)
		print(slot, slot2, item)
		if not item:GetBase().IsOre then
			slot.HoverGradientColor = Colors.Red
		else
			slot.HoverGradientColor = Colors.Money
		end
	end)

	--[[slot:On("DragStop", "DropOre", function(slot, on)
		if not IsValid(on) then return end
		if not on:GetInventory() or not on:GetInventory().IsBackpack then return end
		self:WithdrawItem(slot.ID, on:GetSlot())
		slot.PreventDrop = true
	end)]]

	slot:On("Drop", "DropOre", function(slot, slot2, item)
		if not item:GetBase().IsOre or not item:GetInventory().IsBackpack then return false end

		local nw = Inventory.Networking.Netstack()

		nw:WriteEntity(self)
		nw:WriteUInt(0, 4)
		nw:WriteUInt(slot.ID, 16)
		nw:WriteInventory(item:GetInventory())
		nw:WriteItem(item)

		nw:Send("OreRefinery")

		item:SetAmount(item:GetAmount() - 1)
		return
	end)

	slot:On("DrawBorder", "DrawSmeltingProgress", function(self, w, h, col)
		draw.RoundedBox(4, 0, h/2, w, h/2, Colors.Red)
	end)
	slot.Inventory = self.OreInput
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

function ENT:OnOpenRefine(ref, pnl)
	if IsValid(pnl) then print(pnl) pnl:PopInShow() return pnl end

	local p = vgui.Create("Panel", ref)

	ref:PositionPanel(p)

	local rows = {}

	local fitsOnRow = math.floor(p:GetWide() / (slotSize + slotPadX))
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
			self:CreateItemSlot(slot)

			icX = icX + row.slotW
		end
	end

	--of all the auto-center-fit-buttons-on-rows algorithms i made, this is probably the most elegant tbh
	return p
end

function ENT:OnCloseRefine(ref)

end

function ENT:OpenMenu()
	if IsValid(self.Frame) then return end

	local inv = Inventory.Panels.CreateInventory(LocalPlayer().Inventory.Backpack)
	inv:SetTall(350)
	inv:CenterVertical()

	for k,v in pairs(inv:GetSlots()) do
		v:On("DragStart", "Refinery", function(...) self:OnInventorySlotPickup(...) end)
		v:On("DragStop", "Refinery", function(...) self:OnInventorySlotDrop(...) end)
	end
	local ref = vgui.Create("NavFrame")
	self.Frame = ref
	ref:SetSize(450, 350)
	ref:MakePopup()
	ref:SetPos( ScrW() / 2 - (450 + 8 + inv:GetWide()) / 2,
				ScrH() / 2 - 350 / 2)
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
