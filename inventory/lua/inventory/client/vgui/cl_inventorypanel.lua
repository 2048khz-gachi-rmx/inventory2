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

	if not rec:GetSlot() then errorf("This ItemFrame doesn't have a slot assigned to it! Did you forget to call :SetSlot()?") return end
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

function PANEL:CreateSplitSelection(rec, drop, item)
	if IsValid(self.SplitCloud) then
		self.SplitCloud.BoundTo:SetFakeItem(nil)
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
		if IsValid(self.BoundTo) then self.BoundTo:SetFakeItem(nil) end
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
	no:SetIcon("https://i.imgur.com/vNRPWWn.png", "backarrow.png", 16, 16, nil, 180)

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

function PANEL:SplitItem(rec, drop, item)

	local crossinv = rec:GetInventory() ~= item:GetInventory()
	if crossinv then print("cross-inv splitting is not supported yet :(") return end

	if self.IsWheelHeld then
		local amt = math.floor(item:GetAmount() / 2)

		local ns = Inventory.Networking.Netstack()
		ns:WriteInventory(item:GetInventory())
		ns:WriteItem(item)

		ns:WriteUInt(rec:GetSlot(), 16)
		ns:WriteUInt(amt, 32)

		Inventory.Networking.PerformAction(INV_ACTION_SPLIT, ns)

		return
	end

	if item:GetAmount() == 1 then return end --can't split 1 dude

	local cl, sl, yes, no = self:CreateSplitSelection(rec, drop, item)
	yes.Font = "OSB18"
	sl:SetMinMax(1, item:GetAmount() - 1)
	sl:SetValue(math.floor(item:GetAmount() / 2))

	yes.Label = ("%s -> %s / %s"):format(item:GetAmount(), item:GetAmount() - sl:GetValue(), sl:GetValue())
	local iid = item:GetItemID()

	local meta = Inventory.Util.GetMeta(iid)
	local newitem = meta:new(nil, iid)

	newitem:SetAmount(math.floor(item:GetAmount() / 2))
	newitem:SetSlot(rec:GetSlot())
	function sl:OnValueChanged(new)
		new = math.Round(new)
		newitem:SetAmount(new)
		yes.Label = ("%s -> %s / %s"):format(item:GetAmount(), item:GetAmount() - new, new)
	end

	function yes:DoClick()
		cl:PopOut()
		self.SplitCloud = nil

		local ns = Inventory.Networking.Netstack()
		ns:WriteInventory(item:GetInventory())
		ns:WriteItem(item)

		ns:WriteUInt(rec:GetSlot(), 16)
		local amt = math.Round(sl:GetValue())
		ns:WriteUInt(amt, 32)

		Inventory.Networking.PerformAction(INV_ACTION_SPLIT, ns)
		rec:SetFakeItem(nil)
		rec:SetItem(newitem)
	end

	rec:SetFakeItem(newitem)
end

function PANEL:StackItem(rec, drop, item, amt)

	local crossinv = rec:GetInventory() ~= item:GetInventory()
	if crossinv then print("cross-inv stacking is not supported yet :(") return end

	if not input.IsControlDown() then
		rec:GetInventory():RequestStack(item, rec:GetItem(), amt)
	else
		local max = amt
		local cl, sl, yes, no = self:CreateSplitSelection(rec, drop, item)

		yes.Font = "OSB18"

		sl:SetMinMax(1, max)
		sl:SetValue(math.Round(max / 2))
		sl:SetDecimals(0)
		sl:UpdateNotches()
		yes.Label = ("%s / %s -> %s / %s"):format(item:GetAmount(), rec:GetItem():GetAmount(), item:GetAmount() - sl:GetValue(), rec:GetItem():GetAmount() + sl:GetValue())

		function sl:OnValueChanged(new)
			new = math.Round(new)
			yes.Label = ("%s / %s -> %s / %s"):format(item:GetAmount(), rec:GetItem():GetAmount(), item:GetAmount() - new, rec:GetItem():GetAmount() + new)
		end

		function yes:DoClick()
			cl:PopOut()
			self.SplitCloud = nil

			local val = math.Round(sl:GetValue())

			local ns = Inventory.Networking.Netstack()
			ns:WriteInventory(item:GetInventory())
			ns:WriteItem(rec:GetItem()) --the one we dropped ON (to stack IN)
			ns:WriteItem(item) --the one we DROPPED (to stack OUT OF)
			ns:WriteUInt(val, 32)
			Inventory.Networking.PerformAction(INV_ACTION_MERGE, ns)

			item:SetAmount(item:GetAmount() - val)
			rec:GetItem():SetAmount(rec:GetItem():GetAmount() + val)
		end
	end
end

function PANEL:ItemDrop(rec, drop, item, ...)

	if rec:GetItem() and rec:GetItem():GetItemID() == item:GetItemID() then --there was the same item in that slot;
		self:StackItem(rec, drop, item, amt)
		return
		--[[local amt = rec:GetItem():CanStack(item)							--and it can be stacked
		if amt then
			amt = (self.IsWheelHeld and math.floor(item:GetAmount() / 2)) or amt
		end]]
	end

	if not ((input.IsControlDown() or self.IsWheelHeld) and item:GetCountable()) then --ctrl wasn't held when dropping; move request?
		self:MoveItem(rec, drop, item)
	elseif not rec:GetItem() then 								--dropped onto empty space
		if self:Emit("CanSplitItem", rec, drop, item) == false then return end
		self:SplitItem(rec, drop, item)
	end

end

function PANEL:AddItemSlot()
	local i = #self.Slots

	local it = vgui.Create("ItemFrame", self.Scroll)

	local main = self:GetMainFrame()
	
	local x = i % main.FitsItems
	local y = math.floor(i / main.FitsItems)
	
	it:SetPos( 	8 + x * (main.SlotSize + main.SlotPadding),
				8 + y * (main.SlotSize + main.SlotPadding))

	self.Slots[i + 1] = it
	it:SetInventoryFrame(self)
	it:SetSlot(i + 1)
	it:SetMainFrame(self:GetMainFrame())
	it:On("ItemInserted", self.OnItemAddedIntoSlot, self)

	self:On("Change", it, function(self, inv, ...)
		if inv:GetItemInSlot(i + 1) ~= it:GetItem() then
			it:SetItem(inv:GetItemInSlot(it:GetSlot()))
		end
	end)

	it:On("Drop", "FrameItemDrop", function(...) self:ItemDrop(...) end)
	return it
end

function PANEL:GetItems()
	return self.Items
end

function PANEL:GetSlots()
	return self.Slots
end

function PANEL:Draw(w, h)
	if not self.Inventory then return end
	if self.NoPaint then return end

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