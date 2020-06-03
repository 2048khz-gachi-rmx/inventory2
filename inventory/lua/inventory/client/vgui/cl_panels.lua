--e

local iPan = Inventory.Panels

iPan.FitsItems = 6
iPan.SlotSize = 64
iPan.SlotPadding = 4

function iPan.CreateInventory(par, inv, multiple)

	if not multiple and iPan.IFrame and iPan.IFrame:IsValid() then iPan.IFrame:Remove() end

	local multi_invs = false

	if not inv or (not IsInventory(inv) and IsInventory(next(inv))) then
		multi_invs = true
		inv = LocalPlayer().Inventory
	else
		errorf("Inventory.Panels.CreateInventory: expected nil or table of inventories at arg #2, got #q instead (no inventories there)", type(inv))
	end

	local f = vgui.Create(multi_invs and "NavFrame" or "FFrame", par)
	iPan.IFrame = f
	f:SetMouseInputEnabled(true)
	--64 slot width + 4 slot padding + 16: 8 l,r padding + 4 from idfk where
	f:SetSize((iPan.SlotSize + iPan.SlotPadding) * iPan.FitsItems + 16 + 4, 128)
	f.Shadow = {}

	f.Inventory = inv

	function f:Mask(w, h)
		draw.RoundedPolyBox(8, 0, 0, w, h, color_white)
	end

	function f:PostPaint(w, h)
		--self:Mask(w, h)
		draw.BeginMask(f.Mask, self, w, h)
		draw.DrawOp()
	end

	f:On("PaintOver", function(w, h)
		draw.FinishMask()
	end)

	function f:AppearInventory(p)

		for k,v in ipairs(p.DisappearAnims) do
			v:Stop()
			p.DisappearAnims[k] = nil
		end

		p:SetZPos(0)
		p:Show()
		p:PopIn(0.2, 0)

		local fromabove = p:NewAnimation(0.35, 0, 0.4)
		local _, x = f:GetNavbarSize()
		x = x + 8 --padding
		local y = f.HeaderSize

		fromabove.Think = function(_, pnl, frac)
			local x = x - 8 + 8 * math.min(frac*1.6, 1)^0.7
			local y = y - 12 + 12 * frac

			pnl:SetPos(x, y)
		end


	end

	function f:DisappearInventory(p)
		p:SetZPos(-50)
		local x, y = p:GetPos()

		local slope = p:NewAnimation(0.3, 0, 1.5)
		local fallfrac = 0.6

		slope.Think = function(_, pnl, frac)
			local x = x + 8*frac
			local y = y
			if frac > fallfrac then
				y = y + 4 * Ease( (frac-fallfrac) * (1/fallfrac), 1.7)
			end
			pnl:SetPos(x, y)
		end

		table.InsertVararg(p.DisappearAnims,
			p:PopOut(0.1, 0.1, function(_, self)
				self:Hide()
			end),

			slope
		)

	end


	function f:SetInventory(inv, pnl, noanim)
		if pnl then
			self:AppearInventory(pnl)
			return pnl, true, true
		end

		local p = vgui.Create("InventoryPanel", f)
		EEE = p
		p:SetInventory(inv)
		f.InvPanel = p

		local slots = {}
		local uids = {}

		local trackFunc = function(self, slotnum, it)

			--if uids[it:GetUID()] then --assume there can't be more than one instance of the same item within one inventory
			--	uids[it:GetUID()]:SetItem(nil)
			--end

			uids[it:GetUID()] = self
			PrintTable(uids)
		end

		local unTrackFunc = function(self, it)
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

		f:AppearInventory(p)
		return p, true, true
	end

	function f.OnSelectTab(tab, oldinv, noanim, ...)
		return f:SetInventory(tab.Inventory, oldinv, noanim)
	end

	function f.OnDeselectTab(btn, oldinv)
		if not oldinv then return end
		f:DisappearInventory(oldinv)
	end

	if multi_invs and inv then
		for k,v in pairs(inv) do
			local tab = f:AddTab(v.Name, f.OnSelectTab, f.OnDeselectTab)
			tab:SetTall(50)
			tab.Inventory = v
		end
		f:SetWide(f:GetWide() + 50 + 8)
	end

	return f
end


local f = iPan.CreateInventory()
f:SetTall(320)
f:MakePopup()
f:Center()
f:SelectTab("Backpack")