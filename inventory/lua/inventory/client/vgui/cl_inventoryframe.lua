local PANEL = {}
local iPan = Inventory.Panels

function PANEL:Init()
	local scr = vgui.Create("FScrollPanel", self)
	scr:Dock(FILL)
	scr:DockMargin(0, 32, 0, 0)
	
	scr.GradBorder = true
	scr:GetCanvas():AddDockPadding(0, 8, 0, 8)

	self.Scroll = scr

	self.DisappearAnims = {}

	self.Slots = {}
	self.Items = {}
	self.Inventory = nil
end
										-- V it really do be like that
function PANEL.OnItemAddedIntoSlot(iframe, self, slot, item)
	self.Items[slot] = item
end

function PANEL:OnItemRemovedFromSlot(slot, item)
	self.Items[slot] = nil
end

function PANEL:SetInventory(inv)
	if self.Inventory then
		self.Inventory:RemoveListener("Change", self)
	end

	self.Inventory = inv

	inv:On("Change", self, function(...)
		self:Emit("Change", ...)
	end)

	self:Emit("SetInventory", inv)
end

function PANEL:GetInventory()
	return self.Inventory
end

function PANEL:AddItemSlot()
	local i = #self.Slots

	local it = vgui.Create("ItemFrame", self.Scroll)
	local x = i % iPan.FitsItems
	local y = math.floor(i / iPan.FitsItems)
	it:SetPos( 	8 + x * (iPan.SlotSize + iPan.SlotPadding),
				8 + y * (iPan.SlotSize + iPan.SlotPadding))

	self.Slots[i + 1] = it
	it:SetSlot(i + 1)
	it:On("ItemInserted", self.OnItemAddedIntoSlot, self)

	self:On("Change", it, function(self, inv, ...)
		if inv:GetItemInSlot(i + 1) ~= it:GetItem() then
			print("Changing", it, inv:GetItemInSlot(i + 1))
			it:SetItem(inv:GetItemInSlot(it:GetSlot()))
		end
	end)

	return it
end

function PANEL:GetItems()
	return self.Items
end

function PANEL:GetSlots()

end

function PANEL:Draw(w, h)
	if not self.Inventory then return end
	local inv = self.Inventory
	draw.SimpleText(inv.Name, "OS28", w/2, 16, color_white, 1, 1)
end

function PANEL:Paint(w, h)
    self:PrePaint(w, h)
    self:Draw(w, h)
    self:PostPaint(w, h)
    self:Emit("Paint", w, h)
end


function PANEL:PrePaint()
end
function PANEL:PostPaint()
end


vgui.Register("InventoryPanel", PANEL, "DPanel")