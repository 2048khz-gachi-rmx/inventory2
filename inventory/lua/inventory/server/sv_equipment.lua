--


local function load(act)
	local nw = Inventory.Networking

	act[INV_ACTION_EQUIP] = function(ply)
		local inv = act.readInv(ply)
		local it = act.readItem(ply, inv)
		local eq = net.ReadBool()
		local slot = net.ReadUInt(16)

		if eq then
			--if it:Emit("CanEquip", ply, slot) == false then print("item refused to equip") return end

			local slotName = Inventory.EquipmentSlots[slot]

			local can, why = it:Emit("CanEquip", ply, slotName)
			if can == false then print("cant equip :(", why) return false end

			local em = it:Equip(ply, slot)
			em:Then(function()
				if IsValid(ply) then
					ply:NetworkInventory({inv, ply.Inventory.Character}, INV_NETWORK_UPDATE)
				end
			end)
		else
			local invto = act.readInv(ply)

			local ok = inv:CanCrossInventoryMove(it, invto, slot)
			if not ok then print("cant crossinv bruv") return end -- brugh

			print("unequipping now")
			local em = it:Unequip(ply, slot, invto)
			em:Then(function()
				if IsValid(ply) then
					ply:NetworkInventory({inv, invto}, INV_NETWORK_UPDATE)
				end
			end)

		end

		return false
	end
end

hook.Add("InventoryActionsLoaded", "EquipmentActions", load)

if Inventory.Networking.Actions then
	load(Inventory.Networking.Actions)
end