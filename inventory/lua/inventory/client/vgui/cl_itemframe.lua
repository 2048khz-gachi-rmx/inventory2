local ITEM = {}
local iPan = Inventory.Panels

function ITEM:Init()
    self:SetSize(iPan.SlotSize, iPan.SlotSize)
end

function ITEM:SetItem(it)
	self.Item = it
	self:Emit("ItemInserted", it:GetSlot(), it)
end

function ITEM:PrePaint()
end
function ITEM:PostPaint()
end

local emptyCol = Color(35, 35, 35)
function ITEM:Draw(w, h)
    draw.RoundedBox(8, 0, 0, w, h, emptyCol)

    

    if self.Item then
    	local it = self.Item
    	local name = it:GetName()
    	local wrap = name:WordWrap2(w - 4, "OS14")
    	print(wrap)
    	draw.RoundedBox(8, 0, 0, w, h, Colors.Gray)

    	surface.SetTextColor(color_white)
    	for s in eachNewline(wrap) do
    		local tw = surface.GetTextSize(s)--surface.DrawNewlined(wrap, w/2, 2)
    end
end

function ITEM:Paint(w, h)
    self:PrePaint(w, h)
    self:Draw(w, h)
    self:PostPaint(w, h)
    self:Emit("Paint", w, h)
end

vgui.Register("ItemFrame", ITEM, "Panel")