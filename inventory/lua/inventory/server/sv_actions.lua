


local function load()
	local nw = Inventory.Networking

	local function readInv(ply, act, ignoreaccess)
		local inv, err = nw.ReadInventory()

		if not inv then
			nw.RequestResync(ply)
			errorf("Failed to read inventory from %s: %q", ply, err)
			return
		end

		if not ignoreaccess and act and not inv:HasAccess(ply, act) then
			nw.RequestResync(ply, ply.Inventory, inv)
			errorf("Failed permission check %s from %s on inventory '%s'", act, ply, inv)
			return
		end

		return inv
	end

	local function readItem(ply, inv)
		local it, err = nw.ReadItem(inv)
		if not it then errorf("Failed to read item from %s: %q", ply, err) return end

		return it
	end


	nw.Actions = nw.Actions or {}

	nw.Actions.readInv = readInv
	nw.Actions.readItem = readItem

	nw.Actions[INV_ACTION_DELETE] = function(ply)
		local inv = readInv(ply, "Delete")
		local it = readItem(ply, inv, "Delete")

		if inv and inv:Emit("CanDelete") == false then return end
		if it:Emit("CanDelete") == false then return end

		it:Delete()
		return true, inv
	end

	nw.Actions[INV_ACTION_MOVE] = function(ply)
		local inv = readInv(ply, "Move")
		local it = readItem(ply, inv, "Move")
		local where = net.ReadUInt(16)

		if it:Emit("CanMove", where) == false then return end
		if inv:Emit("CanMoveItem", it, where) == false then print("cannot move item") return end

		local nw = inv:MoveItem(it, where) ~= false

		return nw, inv
	end

	nw.Actions[INV_ACTION_SPLIT] = function(ply)
		local inv = readInv(ply, "Split")
		local it = readItem(ply, inv, "Split")
		local where = net.ReadUInt(16)
		local amt = net.ReadUInt(32)

		if it:Emit("CanSplit", amt) == false then print("cannot split") return end
		if inv:Emit("CanAddItem", it, it:GetUID()) == false then print("cannot add item") return end

		if where > inv.MaxItems or inv:GetItemInSlot(where) then print("where > maxitems or", inv:GetItemInSlot(where)) return end
		if not it:GetCountable() or amt > it:GetAmount() or amt == 0 then return end

		it:SetAmount(it:GetAmount() - amt)

		local dat = table.Copy(it:GetData())
		dat.Amount = amt

		local meta = Inventory.Util.GetMeta(it:GetItemID())
		local new = meta:new(nil, it:GetItemID())
		new:SetOwner(ply)
		new:SetInventory(inv)
		new:SetSlot(where)
		new:SetData(dat)

		inv:InsertItem(new):Then(function(...)
			if IsValid(ply) then ply:UpdateInventory(inv) end
		end, GenerateErrorer("SplitActionInsert"))

		return false, inv
	end

	nw.Actions[INV_ACTION_MERGE] = function(ply)
		local inv = readInv(ply, "Merge")
		local it2 = readItem(ply, inv, "Merge") --to stack OUT OF
		local it = readItem(ply, inv, "Merge") --to stack IN

		local want_amt = math.max(net.ReadUInt(32), 1)

		if it == it2 then return end --no

		local amt = it:CanStack(it2)
		if not amt then return end

		amt = math.min(amt, want_amt)

		it:SetAmount(it:GetAmount() + amt)
		it2:SetAmount(it2:GetAmount() - amt)

		inv:AddChange(it, INV_ITEM_DATACHANGED)
		inv:AddChange(it2, INV_ITEM_DATACHANGED)

		return true, inv
	end

	nw.Actions[INV_ACTION_CROSSINV_MOVE] = function(ply, inv, it, invto)
		inv = inv or readInv(ply, "CrossInventoryFrom")
		it = it or readItem(ply, inv, "CrossInventory")
		invto = invto or readInv(ply, "CrossInventoryTo")

		local where = net.ReadUInt(16)

		local ok = inv:CrossInventoryMove(it, invto, where)

		--if ok ~= false then it:SetSlot(where) end
		return ok
	end

	nw.Actions[INV_ACTION_CROSSINV_MERGE] = function(ply)
		local inv = readInv(ply, "CrossInventoryFrom")
		local it = readItem(ply, inv) -- stack from

		local invto = readInv(ply, "CrossInventoryTo")
		local it2 = readItem(ply, invto)  -- stack to

		local amt = math.max(net.ReadUInt(32), 1)
		amt = math.min(amt, it:GetAmount())

			-- can inv give out the item to invto?
		if not inv:CanCrossInventoryMove(it, invto, it2:GetSlot()) then print("cant crossinv") return false end

		local amt = it2:CanStack(it, amt)

		if not amt or amt == 0 then print("no stack", amt) return false end

		it:SetAmount(it:GetAmount() - amt)
		it2:SetAmount(it2:GetAmount() + amt)

		inv:AddChange(it, INV_ITEM_DATACHANGED)
		inv:AddChange(it2, INV_ITEM_DATACHANGED)
		--if ok ~= false then it:SetSlot(where) end
		return true
	end

	nw.Actions[INV_ACTION_CROSSINV_SPLIT] = function(ply)
		local inv = readInv(ply, "CrossInventoryFrom")
		local it = readItem(ply, inv) -- stack from

		local invto = readInv(ply, "CrossInventoryTo")
		local slot = net.ReadUInt(16)

		local amt = math.max(net.ReadUInt(32), 1)
		amt = math.min(amt, it:GetAmount())

		if it:Emit("CanSplit", amt) == false then print("cant split") return end
		if not inv:CanCrossInventoryMove(it, invto, slot) then print("cant crossinv") return false end

		if slot > invto.MaxItems or invto:GetItemInSlot(slot) then
			print("slot > max or item", slot, invto.MaxItems, invto:GetItemInSlot(slot))
			return
		end
		if not it:GetCountable() or amt > it:GetAmount() or amt == 0 then print("amt invalid") return end

		it:SetAmount(it:GetAmount() - amt)

		local dat = table.Copy(it:GetData())
		dat.Amount = amt

		local meta = Inventory.Util.GetMeta(it:GetItemID())
		local new = meta:new(nil, it:GetItemID())
		new:SetOwner(ply)
		new:SetInventory(invto)
		new:SetSlot(slot)

		invto:InsertItem(new):Then(function()
			local em = new:SetData(dat)

			em:Then(function()
				if IsValid(ply) then
					ply:NetworkInventory(inv, INV_NETWORK_UPDATE)
					ply:NetworkInventory(invto, INV_NETWORK_UPDATE)
				end
			end, GenerateErrorer("InventoryActions"))
		end, GenerateErrorer("InventoryActions"))

		return true
	end

	nw.Actions[INV_ACTION_RESYNC] = function(ply)
		nw.RequestResync(ply)
	end

	net.Receive("Inventory", function(len, ply)
		local act = net.ReadUInt(16)
		if not nw.Actions[act] then errorf("Failed to find action for enum %d from player %s", act, ply) return end

		local ok, needs_nw, inv = xpcall(nw.Actions[act], GenerateErrorer("InventoryActions"), ply)

		if needs_nw then
			ply:NetworkInventory(inv, INV_NETWORK_UPDATE)
		end
	end)

	hook.Run("InventoryActionsLoaded", nw.Actions)
end

load()
