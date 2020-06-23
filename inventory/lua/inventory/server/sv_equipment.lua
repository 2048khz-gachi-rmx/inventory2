--


local function load(act)
	local nw = Inventory.Networking

	act[INV_ACTION_EQUIP] = function(ply)
		local inv = act.readInv(ply, "Equip")
		local it = act.readItem(inv, "Equip")
		print("Received equip request from", ply, inv, it)
		if it:Emit("CanEquip", ply) == false then print("cant equip :(") return false end
		print("equipping :)")
		it:Equip(ply)
	end
end

hook.Add("InventoryActionsLoaded", "EquipmentActions", load)

if Inventory.Networking.Actions then
	load(Inventory.Networking.Actions)
end