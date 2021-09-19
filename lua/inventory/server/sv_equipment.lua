--

local function upd(ply, inv, invto, tok)
	local oldTok = ply:GetInventoryNWToken()
	ply:SetInventoryNWToken(tok)
		ply:RequestUpdateInventory({inv, invto})
	ply:SetInventoryNWToken(oldTok)
end

local function load(act)
	local nw = Inventory.Networking

	act[INV_ACTION_EQUIP] = function(ply)
		local inv = act.readInv(ply)
		local it = act.readItem(ply, inv)
		local eq = net.ReadBool()
		local slot = net.ReadUInt(16)

		local tok = ply:GetInventoryNWToken()

		if eq then
			local slotName = Inventory.EquipmentSlots[slot]

			local can, why = it:Emit("CanEquip", ply, slotName)
			if can == false then return false end

			if not Inventory.CanEquipInSlot(it, slot) then return false end

			local em = it:Equip(ply, slot)
			upd(ply, inv, Inventory.GetEquippableInventory(ply), tok)

		else
			local invto = ply.Inventory.Permanent --act.readInv(ply)

			local ok = inv:CanCrossInventoryMove(it, invto, slot)
			if not ok then return end -- brugh

			local em = it:Unequip(ply, slot, invto)
			upd(ply, inv, Inventory.GetEquippableInventory(ply), tok)
		end

		print(tok, ":", it:GetInventory():GetName())

		return false
	end
end

hook.Add("InventoryActionsLoaded", "EquipmentActions", load)

if Inventory.Networking.Actions then
	load(Inventory.Networking.Actions)
end