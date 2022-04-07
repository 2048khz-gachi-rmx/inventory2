local Inv = Inventory

function Inv.GUIDesiredAction(slot, inv, itm, ipnlFrom, ipnlTo)
	local action
	inv = (IsInventory(inv) and inv) or (inv.GetInventory and inv:GetInventory())
	if not inv then error("what are you giving") return end

	local inv2 = itm:GetInventory()
	if not inv2 then error("didn't find item's inventory") return end

	if slot:GetItem(true) == itm then return false end
	local itm2 = slot:GetItem(true)
	local invPnl = slot:GetInventoryPanel()

	local is_cross = inv ~= inv2

	local can_split = itm:GetCountable() and inv.SupportsSplit and inv2.SupportsSplit

	if ipnlFrom and ((ipnlFrom.SupportsSplit == false) or ipnlFrom:Emit("CanSplit", itm, inv) == false) then
		can_split = false
	end

	if ipnlTo and ((ipnlTo.SupportsSplit == false) or ipnlTo:Emit("CanSplit", itm, inv) == false) then
		can_split = false
	end

	if itm2 and itm:GetItemID() == itm2:GetItemID() then -- second item exists and is the same ID = stack
		local can = itm2:CanStack(itm)

		if not can or can == 0 then -- if we can't stack then use "move"
			action = "Move"
		else
			action = "Merge"
		end
	elseif itm2 then	-- second item exists and isn't the same ID = swap (or move)
		action = "Move"
	elseif (input.IsControlDown() or invPnl.IsWheelHeld) and can_split then -- second item doesnt exist, ctrl/mmb held = split
		action = "Split"
	else -- second item doesn't exist, nothing held = move
		action = "Move"
	end

	return action, is_cross
end



function Inv.GUICanAction(slot, inv, itm, ipnlFrom, ipnlTo)
	local action, is_cross = Inv.GUIDesiredAction(slot, inv, itm, ipnlFrom, ipnlTo)
	if not action then return end

	local inv2 = itm:GetInventory()
	local itm2 = slot:GetItem(true)

	if is_cross then
		if not inv2:CanCrossInventoryMove(itm, inv, slot:GetSlot()) then return false end
		--if not inv:CanCrossInventoryMove(itm, inv2, slot:GetSlot()) then return false end
	else
		if not inv:HasAccess(LocalPlayer(), action, itm) then print("no access 1", inv) return false end
		if not inv2:HasAccess(LocalPlayer(), action, itm) then print("no access 2", inv2) return false end
	end

	if action == "Merge" then
		if not itm2:CanStack(itm) then return false end
	elseif action == "Move" and itm2 and is_cross then -- check if we can put itm2 into inv
		--if not inv2:CanCrossInventoryMove(itm2, inv, itm:GetSlot()) then return false end
		local can = inv:CanCrossInventoryMove(itm2, inv2, itm:GetSlot())
		if not can then return false end
	end

	return action, is_cross
end


hook.Add("InventoryGetOptions", "DeletableOption", function(it, mn)
	if not it:GetDeletable() then return end
	if not it:GetInventory():HasAccess(LocalPlayer(), "Delete", it) then return end

	local opt = mn:AddOption("Delete Item")
	opt.HovMult = 1.15
	opt.Color = Color(150, 30, 30)
	opt.DeleteFrac = 0
	opt.CloseOnSelect = false

	local delCol = Color(230, 60, 60)
	function opt:Think()
		if self:IsDown() then
			self:To("DeleteFrac", 1, 1, 0, 0.25)
		else
			self:To("DeleteFrac", 0, 0.5, 0, 0.3)
		end

		if self.DeleteFrac == 1 and not self.Sent then
			Inventory.Networking.DeleteItem(it)
			self.Sent = true
			mn:PopOut()
			mn:SetMouseInputEnabled(false)
		end
	end

	function opt:PreTextPaint(w, h)
		surface.SetDrawColor(delCol)
		surface.DrawRect(0, 0, w * self.DeleteFrac, h)
	end
end)