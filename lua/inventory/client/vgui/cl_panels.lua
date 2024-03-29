local iPan = Inventory.Panels

iPan.FitsItems = 6
iPan.SlotSize = 80
iPan.SlotPadding = 4
iPan.CloseTime = 0

function Inventory.Panels.CreateInventory(inv, multiple, set)
	if not multiple and iPan.IFrame and iPan.IFrame:IsValid() then iPan.IFrame:Remove() end

	local multi_invs = false

	local has_invs
	if inv then
		local _, firstinv = next(inv)
		has_invs = firstinv
	else --no inv provided; do all of em
		multi_invs = true
		inv = {}

		for k,v in pairs(LocalPlayer().Inventory) do
			local em = v:Emit("ShouldShowF4")

			if em or em == nil then
				inv[k] = v
			end
		end
	end

	if IsInventory(inv) then --only one inventory provided
		--nuthin i guess

	elseif IsInventory(has_invs) or multi_invs then --table of inventories provided
		multi_invs = true
	else --??
		errorf("Inventory.Panels.CreateInventory: expected nil or table of inventories at arg #2, got %q instead (no inventories there)", type(inv))
	end

	local f = vgui.Create("InventoryFrame")

	local slotSize = set and set.SlotSize or iPan.SlotSize
	local slotPad = set and set.SlotPadding or iPan.SlotPadding
	local fits = set and set.FitsItems or iPan.FitsItems

	f.SlotSize = slotSize
	f.SlotPadding = slotPad
	f.FitsItems = fits

	iPan.IFrame = f
	f:SetMouseInputEnabled(true)

	function f:OnKeyCodePressed(key)
		if key == self.CloseByKey then
			iPan.CloseTime = UnPredictedCurTime()
			self:Disappear()
		end
	end

	--64 slot width + 4 slot padding + 16: 8 l,r padding + 4 from idfk where
	f:SetSize((slotSize + slotPad) * fits + 16 + 4, 128)
	f.Shadow = {}


	f.Inventory = inv
	f.AllInventories = all_invs

	local function createTab(invobj)
		if invobj:Emit("CanOpen", inv) == false then return end --uhkay

		local tab = f:AddTab(invobj:GetName(), f.OnSelectTab, f.OnDeselectTab)
		tab:SetTall(64)
		tab.Inventory = invobj

		if invobj.Icon then
			local icDat = invobj.Icon
			local ic = tab:SetIcon(icDat.URL, icDat.Name)

			if icDat.PreserveRatio then
				ic:SetPreserveRatio(true)
			end

			if icDat.OnCreate then
				icDat.OnCreate(ic)
			end
		end

		if invobj:GetDescription() then
			tab:SetDescription(invobj:GetDescription())
		end

		return tab
	end

	if multi_invs and inv then --multiple inventories
		for k,v in pairs(inv) do
			createTab(v)
		end
	elseif inv then --only one inventory
		local tab = createTab(inv)
		if not tab then
			errorf("Attempted to open an inventory tab that didn't allow opening! (%s)", inv)
			return
		end

		f:SetRetractedSize(0)
		tab:Select(true)
	end

	f:SetWide(f:GetWide() + f:GetRetractedSize() + 8)
	f:SetTall(math.max(ScrH() * 0.6, 350))
	function f:DoAnim()
		f.Y = f.Y - 24
		f:MoveBy(0, 24, 0.2, 0, 0.3)
	end

	f:PopIn()
	f:CacheShadow(2, 2, 2)

	return f
end

function iPan.Open()
	if IsValid(iPan.IFrame) then
		iPan.IFrame:Appear()
		return iPan.IFrame
	end

	local f = iPan.CreateInventory()
	f:SetFull(true)
	--f:SetTall(math.max(ScrH() * 0.4, 350))
	f:MakePopup()
	f:Center()
	f:DoAnim()
	f:SelectTab("Backpack", true)

	return f
end

function Inventory.Panels.PickSettings(width)
	local sz = 	(ScrW() < 1200 and ScrW() > 800 and 80)  or		-- 800 - 1200 = 80x80 (with 4 slots per row)
				(ScrW() >= 1200 and ScrW() < 1900 and 64) or	-- 1200 - 1900 = 64x64
				(ScrW() >= 1900 and 80)							-- 1900+ = 80x80 with 6 slots

	local fits

	if width then
		fits = math.floor((width - 4) / sz)
	else
		fits = ScrW() >= 1200 and 6 or 4
	end

	return {
		SlotSize = sz,
		FitsItems = fits,
	}
end

-- makes a panel listen for item hovers and drops
-- emits "ItemHover" - slot, item
-- emits "Drop" - slot, item

function Inventory.Panels.ListenForItem(pnl)

	pnl:Receiver("Item", function(self, tbl, drop)

		if not drop then
			self:Emit("ItemHover", tbl[1], tbl[1].Item)
			return
		end

		self:Emit("Drop", tbl[1], tbl[1].Item)
	end)

end

hook.Add("PlayerButtonDown", "Inventory", function(p, k)
	if k ~= KEY_F4 or not IsFirstTimePredicted() then return end
	if UnPredictedCurTime() - iPan.CloseTime < 0.2 then return end

	local f = iPan.Open()
	f.CloseByKey = KEY_F4
end)