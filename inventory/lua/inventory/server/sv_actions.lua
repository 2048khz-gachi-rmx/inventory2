


local function load()
	local nw = Inventory.Networking

	local function readInv(ply, act, ignoreaccess)
		local inv, err = nw.ReadInventory()
		if not inv then errorf("Failed to read inventory from %s: %q", ply, err) return end
		if not ignoreaccess and not inv:HasAccess(ply, "move") then errorf("Failed permission check from %s on inventory %q", ply, inv) return end

		return inv
	end

	local function readItem(inv, act)
		local it, err = nw.ReadItem(inv)
		if not it then errorf("Failed to read item from %s: %q", ply, err) return end
		return it
	end
	nw.Actions = nw.Actions or {}

	nw.Actions[INV_ACTION_MOVE] = function(ply)
		local inv = readInv(ply, "move")
		local it = readItem(inv, "move")
		local where = net.ReadUInt(16)
		local nw = inv:MoveItem(it, where) ~= false

		return nw, inv
	end



	net.Receive("Inventory", function(len, ply)
		local act = net.ReadUInt(16)
		if not nw.Actions[act] then errorf("Failed to find action for enum %d from player %s", act, ply) return end
		local needs_nw, inv = nw.Actions[act](ply)

		if needs_nw then
			ply:NetworkInventory(inv, INV_NETWORK_UPDATE)
		end
	end)

end


if Inventory.Initted then
	load()
else
	hook.Add("InventoryReady", "InventoryActionsLoad", load)
end
