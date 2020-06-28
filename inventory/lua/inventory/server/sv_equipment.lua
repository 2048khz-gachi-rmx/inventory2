--


local function load(act)
	local nw = Inventory.Networking

	act[INV_ACTION_EQUIP] = function(ply)
		local inv = act.readInv(ply, "Equip")
		local it = act.readItem(ply, inv, "Equip")
		local slot = net.ReadUInt(8)

		local slotName = Inventory.EquipmentSlots[slot]
		_REC = it

		local can, why = it:Emit("CanEquip", ply, slotName)
		if can == false then print("cant equip :(", why) return false end

		local em = it:Equip(ply, slot)
		em:Then(function()
			if IsValid(ply) then
				ply:NetworkInventory({inv, ply.Inventory.Character})
			end
		end)
	end
end

hook.Add("InventoryActionsLoaded", "EquipmentActions", load)

if Inventory.Networking.Actions then
	load(Inventory.Networking.Actions)
end