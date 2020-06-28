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

	local f = vgui.Create("InventoryFrame")--multi_invs and "NavFrame" or "FFrame", par)
	iPan.IFrame = f
	f:SetMouseInputEnabled(true)
	--64 slot width + 4 slot padding + 16: 8 l,r padding + 4 from idfk where
	f:SetSize((iPan.SlotSize + iPan.SlotPadding) * iPan.FitsItems + 16 + 4, 128)
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

	if multi_invs and inv then
		for k,v in pairs(inv) do
			if v:Emit("CanOpen") == false then continue end --uhkay

			local tab = f:AddTab(v.Name, f.OnSelectTab, f.OnDeselectTab)
			tab:SetTall(50)
			tab.Inventory = v
		end
		f:SetWide(f:GetWide() + 50 + 8)
	end

	return f
end

hook.Add("PlayerButtonDown", "Inventory", function(p, k)
	if k ~= KEY_F4 then return end
	local f = iPan.CreateInventory()
	f:SetFull(true)
	f:SetTall(320)
	f:MakePopup()
	f:Center()
	f:SelectTab("Backpack")
end)