


local function load()
	local nw = Inventory.Networking

	local function readInv(ply, act, ignoreaccess)
		local inv, err = nw.ReadInventory()
		if not inv then errorf("Failed to read inventory from %s: %q", ply, err) return end
		if not ignoreaccess and not inv:HasAccess(ply, acr) then errorf("Failed permission check from %s on inventory %q", ply, inv) return end

		return inv
	end

	local function readItem(inv, act, ...)
		local it, err = nw.ReadItem(inv)
		if not it then errorf("Failed to read item from %s: %q", ply, err) return end

		return it
	end
	nw.Actions = nw.Actions or {}

	nw.Actions[INV_ACTION_DELETE] = function(ply)
		local inv = readInv(ply, "Delete")
		local it = readItem(inv, "Delete")

		if inv and inv:Emit("CanDelete") == false then return end
		if it:Emit("CanDelete") == false then return end

		it:Delete()
		return true, inv
	end

	nw.Actions[INV_ACTION_MOVE] = function(ply)
		local inv = readInv(ply, "Move")
		local it = readItem(inv, "Move")
		local where = net.ReadUInt(16)

		if it:Emit("CanMove", where) == false then return end

		local nw = inv:MoveItem(it, where) ~= false
		print("action done, needs Networking?", nw, inv)
		return nw, inv
	end

	nw.Actions[INV_ACTION_SPLIT] = function(ply)
		local inv = readInv(ply, "Split")
		local it = readItem(inv, "Split")
		local where = net.ReadUInt(16)
		local amt = net.ReadUInt(32)

		if it:Emit("CanSplit", amt) == false then return end

		if where > inv.MaxItems or inv:GetItemInSlot(where) then return end
		if not it:GetCountable() or amt > it:GetAmount() or amt == 0 then return end

		it:SetAmount(it:GetAmount() - amt)

		local dat = table.Copy(it:GetData())
		dat.Amount = amt

		local meta = Inventory.Util.GetMeta(it:GetItemID())
		local new = meta:new(nil, it:GetItemID())
		new:SetOwner(ply)
		new:SetInventory(inv)
		new:SetSlot(where)

		new:Insert(inv):Then(function()
			local em = new:SetData(dat)

			em:Then(function()
				if IsValid(ply) then ply:NetworkInventory(inv, INV_NETWORK_UPDATE) end
			end)
		end)

		print("split:", it, where, amt)
		return false, inv
	end

	nw.Actions[INV_ACTION_MERGE] = function(ply)
		local inv = readInv(ply, "Merge")
		local it = readItem(inv, "Merge") --to stack IN
		local it2 = readItem(inv, "Merge") --to stack OUT OF
		local want_amt = math.max(net.ReadUInt(32), 1)

		local amt = it:CanStack(it2)
		if not amt then return end

		amt = math.min(amt, want_amt)

		it:SetAmount(it:GetAmount() + amt)
		it2:SetAmount(it2:GetAmount() - amt)
		return true
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
