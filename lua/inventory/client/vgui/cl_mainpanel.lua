local f = {}

function f:Init()
	self.Attached = {}
end

function f:SetFull(b)
	self.FullInventory = (b==nil and true) or b
end

function f:GetFull()
	return self.FullInventory
end

function f:Mask(w, h)
	draw.RoundedPolyBox(8, 0, 0, w, h, color_white)
end

function f:PostPaint(w, h)

end

function f:AppearInventory(p)
	for k,v in ipairs(p.DisappearAnims) do
		v:Stop()
		p.DisappearAnims[k] = nil
	end

	p:SetZPos(0)
	p:Show()
	p:PopIn(0.2, 0)

	local fromabove = p:NewAnimation(0.35, 0, 0.4)
	local _, x = self:GetNavbarSize()
	x = x + self.RBRadius --padding
	local y = self.HeaderSize

	fromabove.Think = function(_, pnl, frac)
		local off = 16

		local x = x - off + off * frac
		local y = y - 8 + 8 * frac

		pnl:SetPos(x, y)
	end


end

function f:DisappearInventory(p)
	p:SetZPos(-50)
	local x, y = p:GetPos()

	--[[local slope = p:NewAnimation(0.3, 0, 1.5)
	local fallfrac = 0.6

	slope.Think = function(_, pnl, frac)
		local x = x + 8*frac
		local y = y
		if frac > fallfrac then
			y = y + 4 * Ease( (frac-fallfrac) * (1/fallfrac), 1.7)
		end
		pnl:SetPos(x, y)
	end]]
	local slope = p:MoveBy(16, 8, 0.15, 0, 2.1)

	table.InsertVararg(p.DisappearAnims,
		p:PopOut(0.1, 0.05, function(_, self)
			self:Hide()
		end),

		slope
	)

end

function f:GetSlots()
	return self.InvPanel:GetSlots()
end

function f:GetInventory()
	return self.CurrentInventory
end

function f:GetInventoryPanel()
	return self.InvPanel
end

function f:SetInventory(inv, pnl, noanim)
	if pnl then
		self:Emit("SwitchInventory", inv, pnl)
		self:AppearInventory(pnl)
		self.CurrentInventory = inv
		self.InvPanel = pnl

		return pnl, true, true
	end

	local p = vgui.Create("InventoryPanel", self, "InventoryPanel - " .. inv:GetName())

	p:SetFull(self.FullInventory)
	p:SetMainFrame(self)
	p:SetInventory(inv)

	self.InvPanel = p
	self.CurrentInventory = inv

	local slots = {}
	local uids = {}

	local trackFunc = function(self, slotnum, it)

		if not it:GetUID() then return end --uh kay

		uids[it:GetUID()] = self

	end

	local unTrackFunc = function(self, it)
		if not it:GetUID() then return end --uh kay

		if uids[it:GetUID()] == self then uids[it:GetUID()] = nil end
	end

	if not noanim then p:PopIn(0.1, 0.05) end


	if inv.MaxItems then

		for i=1, inv.MaxItems do
			local slot = p:AddItemSlot()
			slots[i] = slot

			slot:On("ItemInserted", "TrackUIDs", trackFunc)
			slot:On("ItemTakenOut", "UntrackUIDs", unTrackFunc)

			local item = inv:GetItemInSlot(i)
			if item then
				slot:SetItem(item)
				uids[item:GetUID()] = slot
			end
		end

	else

		for k,v in pairs(inv:GetItems()) do

		end

	end

	Inventory:On("ItemMoved", p, function(_, inv, item)
		if inv ~= p:GetInventory() then return end

		local newslot = item:GetSlot()

		if slots[newslot].Item ~= item then
			local uid = item:GetUID()

			local prev_slot = uids[uid]
			if IsValid(prev_slot) and prev_slot.Item == item then prev_slot:SetItem(nil) end

			slots[newslot]:SetItem(item)
		end
	end)

	self:Emit("SwitchInventory", inv, p)
	self:AppearInventory(p)

	return p, true, true
end

function f:OnSelectTab(tab, oldinv, noanim, ...)
	return self:SetInventory(tab.Inventory, oldinv, noanim)
end

function f:OnDeselectTab(btn, oldinv)
	if not oldinv then return end
	self:DisappearInventory(oldinv)
end

function f:OnRemove()

	for k,v in ipairs(self.Attached) do
		if not IsValid(v[1]) then continue end
		v[1]:PopOut()
	end

	self:Emit("Remove")
end

function f:GetArea()

	local x, y, mx, my = math.huge, math.huge, 0, 0
	for k,v in ipairs(self.Attached) do
		if not v[1]:IsVisible() or v[1].Disappearing then continue end
		local px, py = v[1]:GetPos()
		local pw, ph = v[1]:GetSize()

		x, y = math.min(x, px), math.min(y, py)
		mx, my = math.max(mx, px + pw), math.max(my, py + ph)
	end

	local px, py = self:GetPos()
	local pw, ph = self:GetSize()

	x, y = math.min(x, px), math.min(y, py)
	mx, my = math.max(mx, px + pw), math.max(my, py + ph)

	--x, y, w, h
	return x, y, mx - x, my - y
end

function f:AreaChanged(x, y, w, h)

	local nx, ny, nw, nh = self:GetArea()

	local dx, dy = nw - w, nh - h --difference in x, y

	local mx, my = 0, 0 --main panel position
	if self.AreaMovingX then
		mx = self.AreaMovingX
		my = self.AreaMovingY
		self.AreaAnim:Stop()
	else
		mx, my = self:GetPos()
	end

	self.ohGodWhyWhat = ((self.ohGodWhyWhat or 0) + 1) % 2  --AHAHAHHAHAHAHH FUCK SUBPIXEL SHIT ADUIASDIUASBDOCUINASUODCINASIOC
	self.AreaMovingX = mx - math[self.ohGodWhyWhat == 1 and "floor" or "ceil"](dx/2)
	self.AreaMovingY = my

	local anim = self:NewAnimation(0.3, 0, 0.3)
	self.AreaAnim = anim
	anim.Think = BlankFunc

	anim:On("Think", function(_, fr)
		self:SetPos(mx - (dx / 2 * fr), my)
		self:Emit("Drag")
	end)

	anim:On("End", function()
		self:SetPos(self.AreaMovingX, self.AreaMovingY)
		self.AreaMovingX, self.AreaMovingY = nil, nil
	end)

end

function f:Attach(p, posfunc)
	local t = {p, posfunc}
	self.Attached[#self.Attached + 1] = t

	local f = function(...)
		if p.Detached then return end
		return posfunc(...)
	end

	self:On("PerformLayout", p, f, p)
	self:On("Drag", p, f, p)
	return t
end

function f:AddInventoryPanel(p, inv, posfunc)

	if not isfunction(posfunc) then error("Required function for positioning panel.") return end
	if isstring(p) then
		p = vgui.Create(p, nil, p .. " - " .. inv:GetName() .. " (attached to " .. tostring(self) .. ")")
		p:PopIn()
	end

	self:Attach(p, posfunc)[3] = inv

	if inv then

		self:On("SwitchInventory", inv.Name, function(self, newinv, invpnl)

			if newinv == inv then
				if not p:IsVisible() then
					local x, y, w, h = self:GetArea()
					p:PopInShow()
					p.Disappearing = false
					timer.Simple(0, function() self:AreaChanged(x, y, w, h) end)
				end
				return
			end

			if IsValid(p) and p:IsVisible() then
				local x, y, w, h = self:GetArea()
				p:PopOutHide()
				p.Disappearing = true
				timer.Simple(0, function() self:AreaChanged(x, y, w, h) end)
			end
		end)

	end

	return p
end


vgui.Register("InventoryFrame", f, "NavFrame")