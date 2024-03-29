local PANEL = {}
local iPan = Inventory.Panels

function PANEL:Init()
	self:EnableName(true)

	local scr = vgui.Create("FScrollPanel", self)
	scr:Dock(FILL)

	scr.GradBorder = true
	scr:GetCanvas():AddDockPadding(0, 8, 0, 8)

	self.GradColor = scr.BorderColor
	self.Scroll = scr

	self.DisappearAnims = {}

	self.Slots = {}
	self.Items = {}
	self.Inventory = nil
end

function PANEL:EnableName(b)
	self._NameEnabled = b

	if not b then
		self:DockPadding(4, 4, 4, 4)
	else
		self:DockPadding(4, 32, 4, 4)
	end
end

function PANEL:Think()
	if dragndrop.IsDragging() then --motherfuckin dragndrop
		self.IsWheelHeld = input.IsMouseDown(MOUSE_MIDDLE)
	end
	self:Emit("Think")
end


function PANEL:SetFull(b)
	self.FullInventory = (b==nil and true) or b
end

function PANEL:GetFull()
	return self.FullInventory
end
ChainAccessor(PANEL, "MainFrame", "MainFrame")
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

	inv:Emit("OpenFrame", self:GetMainFrame(), self)
	self:Emit("SetInventory", inv)
end

function PANEL:GetInventory()
	return self.Inventory
end

function PANEL:MoveItem(rec, drop, item)
	local crossinv = rec:GetInventory() ~= item:GetInventory()

	if not rec:GetSlot() then
		errorf("This ItemFrame doesn't have a slot assigned to it! Did you forget to call :SetSlot()?")
		return
	end
	if rec.Item == item then return end

	local recItem = rec:GetItem(true)

	if crossinv then
		local ok = item:GetInventory():RequestCrossInventoryMove(item, rec:GetInventory(), rec:GetSlot())

		if ok then
			rec:SetItem(item)
			drop:SetItem(recItem)
		end

	else
		local ok = item:GetInventory():RequestMove(item, rec:GetSlot())

		if ok then
			rec:SetItem(item)
			drop:SetItem(recItem)
		end
	end

	--[[local ns = Inventory.Networking.Netstack()

	ns:WriteInventory(item:GetInventory())
	ns:WriteItem(item)
	if crossinv then ns:WriteInventory(rec:GetInventory()) end

	ns:WriteUInt(rec:GetSlot(), 16)

	item:SetSlot(rec:GetSlot()) --assume success

	if crossinv then
		item:Delete() --remove self from old inv
		rec:GetInventory():AddItem(item) --add self to new inv
	end

	Inventory.Networking.PerformAction(crossinv and INV_ACTION_CROSSINV_MOVE or INV_ACTION_MOVE, ns)]]
end

function PANEL:CreateSplitSelection(rec, drop, item, fake)
	if IsValid(self.SplitCloud) then
		self.SplitCloud:Remove()
	end

	local crossinv = rec:GetInventory() ~= item:GetInventory()

	local cl = vgui.Create("DPanel", rec:GetParent())
	self.SplitCloud = cl
	cl:SetZPos(100)
	local col = ColorAlpha(Colors.Gray, 200)
	function cl:Paint(w, h)
		local x, y = self:LocalToScreen(0, 0)
		surface.SetDrawColor(color_white)
		BSHADOWS.BeginShadow()
			draw.RoundedBox(4, x, y, w, h, col)
		BSHADOWS.EndShadow(2, 1, 1, self:GetAlpha())
	end

	function cl:OnRemove()
		local f = self.BoundTo
		if IsValid(f) and f:GetItem() == fake then
			f:SetFakeItem(nil)
		end
		self.SplitCloud = nil
	end

	cl:SetMouseInputEnabled(true)

	local x, y = rec:GetPos()
	cl:SetSize(150, 32 + 20 + 4)
	cl:SetPos( math.Clamp(x + rec:GetWide() / 2 - cl:GetWide() / 2, 0, self:GetWide() - cl:GetWide() - 8),
			   math.max(y - cl:GetTall() + 8, 8) )
	cl:PopIn()
	cl:MoveBy(0, -8, 0.3, 0, 0.4)
	cl.BoundTo = rec

	local sl = cl:Add("FNumSlider")
	sl:DockPadding(4, 0, 4, 0)

	sl:Dock(TOP)
	sl:SetDecimals(0)
	sl.Slider:SetNotches(1)

	local no = cl:Add("FButton")
	no:SetPos(4, sl:GetTall())
	no:SetSize(cl:GetWide()/2 - 4 - 2 - 32, 20)
	no:SetColor(Color(170, 50, 50))
	no:SetIcon("https://i.imgur.com/vNRPWWn.png", "backarrow.png", 16, 16)

	no.DoClick = function()
		cl:PopOut()
		self.SplitCloud = nil
	end

	local yes = cl:Add("FButton")
	yes:SetPos(cl:GetWide()/2 + 2 - 32, sl:GetTall())
	yes:SetSize(cl:GetWide()/2 - 4 - 2 + 32, 20)
	yes:SetColor(Colors.Sky)


	return cl, sl, yes, no

end

function PANEL:SplitItem(rec, drop, item, amt)
	local crossinv = rec:GetInventory() ~= item:GetInventory()
	local act_enum = crossinv and INV_ACTION_CROSSINV_SPLIT or INV_ACTION_SPLIT

	local ns = Inventory.Networking.Netstack()
	ns:WriteInventory(item:GetInventory())
	ns:WriteItem(item)

	if crossinv then
		ns:WriteInventory(rec:GetInventory())
	end
	ns:WriteUInt(rec:GetSlot(), 16)
	ns:WriteUInt(amt, 32)

	Inventory.Networking.PerformAction(act_enum, ns)
end


function PANEL:StartSplitItem(rec, drop, item)
	local crossinv = rec:GetInventory() ~= item:GetInventory()
	local act_enum = crossinv and INV_ACTION_CROSSINV_SPLIT or INV_ACTION_SPLIT
	--if crossinv then print("cross-inv splitting is not supported yet :(") return end

	local inv = self:GetInventory()
	local ipnl = self

	if self.IsWheelHeld then
		local amt = math.floor(item:GetAmount() / 2)

		self:SplitItem(rec, drop, item, amt)

		return
	end

	if item:GetAmount() == 1 then return end --can't split 1 dude

	local iid = item:GetItemID()
	local newitem = Inventory.NewItem(iid)

	local cl, sl, yes, no = self:CreateSplitSelection(rec, drop, item, newitem)
	yes.Font = "OSB18"
	sl:SetMinMax(1, item:GetAmount() - 1)
	sl:SetValue(math.floor(item:GetAmount() / 2))

	yes.Label = ("%s / %s"):format(item:GetAmount() - sl:GetValue(), sl:GetValue())

	newitem:SetAmount(math.floor(item:GetAmount() / 2))
	newitem:MoveToSlot(rec:GetSlot())
	function sl:OnValueChanged(new)
		new = math.floor(new)
		newitem:SetAmount(new)
		yes.Label = ("%s / %s"):format(item:GetAmount() - new, new)
		inv:Emit("Change")
	end

	function yes:DoClick()
		cl:PopOut()
		self.SplitCloud = nil

		local amt = math.floor(sl:GetValue())
		ipnl:SplitItem(rec, drop, item, amt)

		rec:SetFakeItem(nil)
		rec:SetItem(newitem)
	end

	rec:SetFakeItem(newitem)

	self:GetInventory():Emit("Change")

	rec:On("InventoryUpdated", cl, function()
		if rec:GetItem(true) then
			print("boppnig out 1")
			cl:PopOut()
			cl:SetMouseInputEnabled(false)
		end
	end)

	drop:On("InventoryUpdated", cl, function()
		if drop:GetItem(true) ~= item then
			print("boppnig out 2")
			cl:PopOut()
			cl:SetMouseInputEnabled(false)
		end
	end)
end

function PANEL:StackItem(rec, drop, item, amt)
	local crossinv = rec:GetInventory() ~= item:GetInventory()
	local act_enum = crossinv and INV_ACTION_CROSSINV_MERGE or INV_ACTION_MERGE

	if not input.IsControlDown() then
		amt = self.IsWheelHeld and math.min(amt or math.huge, math.floor(item:GetAmount() / 2)) or amt
		rec:GetInventory():RequestStack(item, rec:GetItem(), amt)
		rec:GetInventory():Emit("Change")
	else

		local max = rec:GetItem():CanStack(item, item:GetAmount())
		local cl, sl, yes, no = self:CreateSplitSelection(rec, drop, item)

		yes.Font = "OSB18"

		sl:SetMinMax(1, max)
		sl:SetValue(math.Round(max / 2))
		sl:SetDecimals(0)
		sl:UpdateNotches()
		yes.Label = ("%s / %s"):format(item:GetAmount() - sl:GetValue(), rec:GetItem():GetAmount() + sl:GetValue())

		function sl:OnValueChanged(new)
			new = math.floor(new)
			yes.Label = ("%s / %s"):format(item:GetAmount() - new, rec:GetItem():GetAmount() + new)
		end

		function yes:DoClick()
			cl:PopOut()
			self.SplitCloud = nil

			local val = math.floor(sl:GetValue())

			rec:GetInventory():RequestStack(item, rec:GetItem(), val)
			rec:GetInventory():Emit("Change")
			--[[item:SetAmount(item:GetAmount() - val)
			rec:GetItem():SetAmount(rec:GetItem():GetAmount() + val)]]
		end
	end
end

function PANEL:ItemDrop(rec, drop, item, ...)
	if item:GetInventory().IsCharacterInventory then
		drop:GetInventoryPanel():Emit("UnequipRequest", rec, drop, item)
		return
	end

	local dp = drop:GetInventoryPanel()
	local df = dp and dp:GetMainFrame()

	local sf = self:GetMainFrame()

	if df and df:Emit("ItemDropFrom", rec, self, item) == false then
		return
	end

	if sf and sf:Emit("ItemDropOn", rec, drop, item) == false then
		return
	end

	local action = Inventory.GUICanAction(rec, self:GetInventory(), item, self, drop:GetInventoryPanel())

	if action == "Move" then
		self:MoveItem(rec, drop, item)
	elseif action == "Split" then
		self:StartSplitItem(rec, drop, item)
	elseif action == "Merge" then
		self:StackItem(rec, drop, item)
	end

end

function PANEL.CheckCanDrop(slotTo, invpnl, slotFrom, itm)
	-- HoverGradientColor

	local can, why = Inventory.GUICanAction(
		slotTo, invpnl:GetInventory(), itm,
		slotFrom:GetInventoryPanel(), slotTo:GetInventoryPanel()
	)

	if not can and invpnl:GetInventory().VerbosePermissions then
		print("CheckCanDrop - ", why or "no error")
	end

	if not can and not slotTo.HoverGradientColor then
		slotTo.HoverGradientColor = Colors.DarkerRed
		slotTo._BecauseCant = true
	elseif can and slotTo._BecauseCant then
		slotTo.HoverGradientColor = nil
		slotTo._BecauseCant = false
	end

end

function PANEL.OnItemClick(itmpnl, invpnl, slot, itm)
	invpnl:Emit("Click", itmpnl, slot, itm)
end

function PANEL.OnItemFastAction(itmpnl, invpnl, why)
	invpnl:Emit("FastAction", itmpnl, why)
end

PANEL.XPadding = 8
PANEL.YPadding = 8

function PANEL:TrackItemSlot(it, sl)
	self.Slots[sl] = it
	it:SetInventoryPanel(self)
	it:SetSlot(sl)
	it:SetMainFrame(self:GetMainFrame())
	it:On("ItemInserted", self, self.OnItemAddedIntoSlot, self)
	it:On("ItemHover", self, self.CheckCanDrop, self)
	it:On("Click", self, self.OnItemClick, self)
	it:On("FastAction", self, self.OnItemFastAction, self)
	it:On("Drop", "FrameItemDrop", function(...) self:ItemDrop(...) end)

	it:BindInventory(self:GetInventory(), it:GetSlot())
end

function PANEL:AddItemSlot()
	local i = #self.Slots

	local it = vgui.Create("ItemFrame", self.Scroll, "ItemFrame for InventoryPanel")

	local main = self:GetMainFrame()

	if main then
		local x = i % main.FitsItems
		local y = math.floor(i / main.FitsItems)

		it:SetPos( 	self.XPadding + x * (main.SlotSize + main.SlotPadding),
					self.YPadding + y * (main.SlotSize + main.SlotPadding))

		self.ItemLines = math.max(self.ItemLines or 0, y)
	end

	self:TrackItemSlot(it, i + 1)

	return it
end

function PANEL:GetItemLines()
	return self.ItemLines + 1
end

function PANEL:GetLinesHeight()
	local main = self:GetMainFrame()
	return self.YPadding * 2 + (self:GetItemLines() * (main.SlotSize + main.SlotPadding) - main.SlotPadding)
end

function PANEL:GetItems()
	return self.Items
end

function PANEL:GetSlots()
	return self.Slots
end

function PANEL:GetSlot(i)
	return self.Slots[i]
end

function PANEL:Draw(w, h)
	if not self.Inventory then return end
	if self.NoDraw or not self._NameEnabled then return end

	local inv = self.Inventory
	draw.SimpleText(inv:GetName(), "OS28", w/2, 16, color_white, 1, 1)
end

function PANEL:SetShouldPaint(b)
	self.NoDraw = not b
	self.Scroll.NoDraw = self.NoDraw
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