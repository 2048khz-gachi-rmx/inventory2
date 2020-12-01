local iPan = Inventory.Panels

iPan.FitsItems = 6
iPan.SlotSize = 80
iPan.SlotPadding = 4

function iPan.CreateInventory(inv, multiple, set)

	if not multiple and iPan.IFrame and iPan.IFrame:IsValid() then iPan.IFrame:Remove() end

	local multi_invs = false

	local has_invs

	if inv then
		local _, firstinv = next(inv)
		has_invs = firstinv
	end

	if not inv then --no inv provided; do all of em
		multi_invs = true
		inv = LocalPlayer().Inventory

	elseif IsInventory(inv) then --only one inventory provided
		--nuthin i guess

	elseif IsInventory(has_invs) then --table of inventories provided
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



	--64 slot width + 4 slot padding + 16: 8 l,r padding + 4 from idfk where
	f:SetSize((slotSize + slotPad) * fits + 16 + 4, 128)
	f.Shadow = {}


	f.Inventory = inv

	--[[hook.Add("PostRenderVGUI", f, function()
		local x, y, w, h = f:GetArea()
		surface.SetDrawColor(Colors.Red)
		surface.DrawOutlinedRect(x, y, w, h)

		surface.SetDrawColor(0, 255, 0)
		surface.DrawRect(x + w/2 - 1, y + h/2 - 1, 2, 2)
		surface.SetDrawColor(0, 0, 255)
		surface.DrawRect(ScrW() / 2, ScrH() / 2, 3, 3)
	end)]]

	if multi_invs and inv then --multiple inventories
		for k,v in pairs(inv) do
			if v:Emit("CanOpen") == false then continue end --uhkay

			local tab = f:AddTab(v.Name, f.OnSelectTab, f.OnDeselectTab)
			tab:SetTall(50)
			tab.Inventory = v
		end
	elseif inv then --only one inventory
		if inv:Emit("CanOpen") == false then return end --uhkay

		local tab = f:AddTab(inv.Name, f.OnSelectTab, f.OnDeselectTab)
		tab:SetTall(50)
		tab.Inventory = inv
		tab:Select(true)
	end

	f:SetWide(f:GetWide() + 50 + 8)
	f:SetTall(math.max(ScrH() * 0.4, 350))

	return f
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
	local f = iPan.CreateInventory()
	f:SetFull(true)
	--f:SetTall(math.max(ScrH() * 0.4, 350))
	f:MakePopup()
	f:Center()
	f:SelectTab("Backpack")
end)