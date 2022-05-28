local function load()
	local nw = Inventory.Networking

	local cur_invs = {}

	local function readInv(ply, act, ignoreaccess)
		local inv, err = nw.ReadInventory(false)

		if not inv then
			nw.RequestResync(ply)
			errorf("Failed to read inventory from %s: %q", ply, err)
			return
		end

		if not ignoreaccess and act and not inv:HasAccess(ply, act) then
			-- todo: security issue? networking inventories player has no access to...
			nw.RequestResync(ply, ply.Inventory) --, inv)
			errorf("Failed permission check %s from %s on inventory '%s'", act, ply, inv)
			return
		end

		cur_invs[#cur_invs + 1] = inv
		return inv
	end

	local function readItem(ply, inv)
		local it, err = nw.ReadItem(inv)
		if not it then
			errorf("Failed to read item from %s: %q", ply, err)
			return
		end

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

		if it:Emit("CanSplit", amt) == false then
			print("cannot split")
			return
		end

		if where > inv.MaxItems or inv:GetItemInSlot(where) then
			print("where > maxitems or item already in slot:", inv:GetItemInSlot(where), where, inv.MaxItems)
			return
		end

		if not it:GetCountable() or amt > it:GetAmount() or amt == 0 then
			return
		end

		local dat = table.Copy(it:GetData())
		dat.Amount = amt

		local new = Inventory.NewItem(it:GetItemID())
		new:SetData(dat)
		new:SetOwner(ply)
		new:SetInventory(inv)
		new:SetSlotRaw(where)

		if inv:Emit("CanAddItem", new) == false then
			return
		end

		it:SetAmount(it:GetAmount() - amt)
		new:SetSlot(where)

		Inventory.Networking.RequestUpdate(ply, inv)
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

		it:AddChange(INV_ITEM_DATACHANGED)
		it2:AddChange(INV_ITEM_DATACHANGED)

		return true, inv
	end

	nw.Actions[INV_ACTION_CROSSINV_MOVE] = function(ply, inv, it, invto)
		inv = inv or readInv(ply)
		it = it or readItem(ply, inv, "CrossInventory")
		invto = invto or readInv(ply)

		local where = net.ReadUInt(16)

		if not invto:ValidateSlot(where) then
			return false, "bad slot"
		end

		-- local can, why = inv:CanCrossInventoryMove(it, invto, where, ply)
		-- if not can then return can, why end

		--[[
		if not inv:HasAccess(ply, "CrossInventoryFrom", it, invto, where) then
			return false, "no access - from"
		end

		if not invto:HasAccess(ply, "CrossInventoryTo", it, inv, where) then
			return false, "no access - to"
		end
		]]

		local ok, why = inv:CrossInventoryMove(it, invto, where, ply)
		if not ok then return false, why end

		return ok
	end

	nw.Actions[INV_ACTION_CROSSINV_MERGE] = function(ply)
		local inv = readInv(ply)
		local it = readItem(ply, inv, "CrossInventory") -- stack from

		local invto = readInv(ply)
		local it2 = readItem(ply, invto, "CrossInventory")  -- stack to

		if inv == invto then
			errorNHf("why are you crossinv-merging into the same inv fucking tard %s", inv)
			return false, "bad inv"
		end

		local amt = math.max(net.ReadUInt(32), 1)
		amt = math.min(amt, it:GetAmount())

		-- we won't be swapping the items, only stacking
		local can, why = inv:CanCrossInventoryMove(it, invto, it2:GetSlot(), ply)
		if not can then return can, why end

		amt = it2:CanStack(it, amt)
		if not amt or amt == 0 then return false, "bad stack: " .. amt end

		it:SetAmount(it:GetAmount() - amt)
		it2:SetAmount(it2:GetAmount() + amt)

		it:AddChange(INV_ITEM_DATACHANGED) -- ?
		it2:AddChange(INV_ITEM_DATACHANGED)

		inv:EmitHook("CrossStackOut", it, it2, amt)
		invto:EmitHook("CrossStackIn", it, it2, amt)

		--if ok ~= false then it:SetSlot(where) end
		return true
	end

	nw.Actions[INV_ACTION_CROSSINV_SPLIT] = function(ply)
		local inv = readInv(ply)
		local it = readItem(ply, inv, "CrossInventory") -- stack from

		local invto = readInv(ply)
		local slot = net.ReadUInt(16)

		if inv == invto then
			errorNHf("why are you crossinv-merging into the same inv fucking tard %s", inv)
			return false, "bad inv"
		end

		if not invto:ValidateSlot(slot) then
			return false, "invalid split slot"
		end

		local amt = math.max(net.ReadUInt(32), 1)
		amt = math.min(amt, it:GetAmount())

		if it:Emit("CanSplit", amt) == false then
			it.AttemptSplit = nil
			return
		end

		if invto:GetItemInSlot(slot) then
			return false, "already have an item in slot"
		end

		if slot > invto.MaxItems then
			return false, "slot > max"
		end

		if not it:GetCountable() or amt > it:GetAmount() or amt == 0 then
			return false, "invalid amt"
		end

		-- create new item
		local dat = table.Copy(it:GetData())
		dat.Amount = amt

		-- we're guaranteed to not have an item there, dont check swap
		if not inv:CanCrossInventoryMove(it, invto, slot, ply) then
			return false, "CanCrossInvMove gave false"
		end

		local new = Inventory.NewItem(it:GetItemID())
		new:SetData(dat)
		new:SetOwner(ply)
		new:SetInventory(inv)
		new:SetSlotRaw(slot)

		-- try moving this new item cross
		if not inv:CanCrossInventoryMove(new, invto, slot, ply) then
			return false, "CanCrossInvMove on temp item gave false"
		end

		-- all good; now actually do it
		it:SetAmount(it:GetAmount() - amt)
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

	nw.Actions[INV_ACTION_PICKUP] = function(ply)
		local inv = inv or readInv(ply)
		local it = readItem(ply, inv, "CrossInventory")
		local invto = invto or readInv(ply)

		if not inv:HasAccess(ply, "CrossInventoryFrom", it, invto, where) then
			return false, "no access - from"
		end

		if not invto:HasAccess(ply, "CrossInventoryTo", it, inv, where) then
			return false, "no access - to"
		end

		local ok, prs, new = invto:PickupItem(it)

		if prs then
			prs:Then(function(...)
				ply:UpdateInventory(inv)
				ply:UpdateInventory(invto)
			end, function(...)
				print("bad pickup request from", ply, ...)
			end)
		end
	end

	nw.Actions[INV_ACTION_USE] = function(ply)
		local inv = inv or readInv(ply)
		local it = readItem(ply, inv, "Use")
		if not it then return end

		if not inv:HasAccess(ply, "Use", it) then
			return false, "no access from inventory"
		end

		local meta = Inventory.Util.GetMeta(it:GetIID())
		if not meta.PlayerUse then
			print(ply, "tried to use item without a .Use method", it:GetIID(), it:GetUID())
			return
		end

		local needUpdate, needFull = meta.PlayerUse(it, ply)

		if needUpdate then
			if needFull then
				ply:NetworkInventory(isbool(needUpdate) and inv or needUpdate)
			else
				ply:UpdateInventory(isbool(needUpdate) and inv or needUpdate)
			end
		end
	end

	nw.Actions[INV_ACTION_RESYNC] = function(ply)
		nw.RequestResync(ply)
	end

	net.Receive("Inventory", function(len, ply)
		local act = net.ReadUInt(16)
		local token = net.ReadUInt(16)
		if not nw.Actions[act] then errorf("Failed to find action for enum %d from player %s", act, ply) return end

		ply:SetInventoryNWToken(token)
		local ok, succ, inv = xpcall(nw.Actions[act], GenerateErrorer("InventoryActions"), ply)


		if succ == false then
			printf("action %s failed - %s", act, inv or "no error")
			-- resync all inventories the player wrote that they have access to
			nw.RequestResync(ply, unpack(cur_invs))
		elseif succ then
			ply:NetworkInventory(inv, INV_NETWORK_UPDATE)
		end

		table.Empty(cur_invs)
		ply:SetInventoryNWToken(nil)
	end)

	hook.Run("InventoryActionsLoaded", nw.Actions)
end

load()
