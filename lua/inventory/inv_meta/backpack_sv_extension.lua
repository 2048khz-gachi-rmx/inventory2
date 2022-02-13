local bp = Inventory.Inventories.Backpack
ChainAccessor(bp, "LastResync", "LastResync")
--[[
	returns a promise (and maybe a number)
		- resolved with a table of items = those items were added
		- resolved with false and a table of items = those items got stacked into

	the maybe number is the amount of items left which couldnt be stacked in anywhere
]]

function bp:NewItem(iid, slot, dat, nostack)
	if not isstring(iid) and not isnumber(iid) then
		errorf("Attempted to create item with IID: %s (%s)", iid, type(iid))
		return
	end

	local pr = Promise()

	local can, why = self:Emit("CanCreateItem", iid, dat, slot)
	if can == false then return false, ("Cannot create item (%s)"):format(why or "emit returned false") end


	if not nostack then
		local its, left = Inventory.CheckStackability(self, iid, dat)

		-- table of new items given; now to insert them in SQL
		if istable(its) then
			local prs = {}
			for k,v in ipairs(its) do
				local newPr = Promise()
				table.insert(prs, newPr)

				if self.UseSQL ~= false then
					v:Insert(self)
					self:AddItem(v, true)

					v:On("AssignUID", "InsertIntoInv", function(v, uid)
						self:AddChange(v, INV_ITEM_ADDED)
						newPr:Resolve(v)
					end)
				else
					newPr:Resolve(v)
				end
			end


			return Promise.OnAll(prs), left
		end

		if its == true then
			pr:Resolve(false, left)
			return pr, 0
		end
	end

	slot = slot or self:GetFreeSlot()
	if not slot or slot > self.MaxItems then
		pr:Reject( ("Didn't find a slot where to put the item or it was above MaxItems! (%s > %d)"):format(slot, self.MaxItems) )
		return pr, dat and dat.Amount or 0
	end

	local it = Inventory.NewItem(iid, self, dat)
	it:SetSlot(slot)

	if self.UseSQL ~= false then
		it:Insert(self)
		self:AddItem(it, true)

		it:Once("AssignUID", function()
			pr:Resolve({it})
		end)
	else
		pr:Resolve({it})
	end

	return pr, 0
end

function bp:NewItemNetwork(who, iid, slot, dat, nostack)

	if isnumber(who) or isstring(who) then
		-- shift args 1 up
		nostack = dat
		dat = slot
		slot = iid
		iid = who

		who = self:GetOwner()
	end

	local pr, left = self:NewItem(iid, slot, dat, nostack)

	pr:Then(function(...)
		if IsValid(self:GetOwner()) then
			Inventory.Networking.NetworkInventory(who, self, INV_NETWORK_UPDATE)
		end
	end)

	return pr, left
end

-- can you move FROM this inv?
function bp:CanCrossInventoryMove(it, inv2, slot, ply)
	-- check if they have that slot available

	if slot and inv2:IsSlotLegal(slot) == false then return false end

	if ply and not inv2:HasAccess(ply, "CrossInventoryTo", it, self) then print("cant - to") return false end
	if ply and not self:HasAccess(ply, "CrossInventoryFrom", it, inv2) then print("cant - from") return false end

	-- check if inv2 can accept cross-inventory item
	if inv2:Emit("CanMoveTo", it, self, slot) == false then print("CanMoveTo no", inv2) return false end

	-- check if we can give out the item
	if self:Emit("CanMoveFrom", it, inv2, slot) == false then print("CanMoveFrom no") return false end

	-- check if inv2 can add an item to itself
	if inv2:Emit("CanAddItem", it, it:GetUID(), slot) == false then print("CanAdd no") return false end

	-- check if the item can be moved
	if it:Emit("CanCrossMove", self, inv2, slot) == false then print("CanItemAdd no") return false end

	return true
end

-- inv1: from, inv2: to
local function ActuallyMove(inv1, inv2, it, slot)
	--local em = Inventory.MySQL.SetInventory(it, inv2, slot)

	inv1:RemoveItem(it, true, true) -- don't write the change 'cause we have crossmoves as a separate change
	it:SetSlot(slot)
	inv2:AddItem(it, true, true) -- same shit

	assert(it:GetInventory() == inv2)

	inv2:AddChange(it, INV_ITEM_CROSSMOVED)

end

-- move from bp to inv2
function bp:CrossInventoryMove(it, inv2, slot, ply)
	if not IsInventory(inv2) then
		errorf("CrossInventoryMove between what invs")
		return
	end

	if it:GetInventory() ~= self then
		errorf("Can't move an item from an inventory which it doesn't belong to!" ..
			"(item) %s vs %s (self)", it:GetInventory(), self)
		return
	end

	slot = slot or inv2:GetFreeSlot()
	if not slot then print("Can't cross-inventory-move cuz no slot", slot) return false end
	if not inv2:IsSlotLegal(slot) then printf("Attempted to move item out of inventory bounds (%s > %s)", slot, inv2.MaxItems) return end

	local other_item = inv2:GetItemInSlot(slot)

	if other_item then
		if not inv2:CanCrossInventoryMove(other_item, self, it:GetSlot(), ply) then print(inv2, "#1 doesn't allow CIM") return false end
	end

	if not self:CanCrossInventoryMove(it, inv2, nil, ply) then print(self, "#2 doesn't allow CIM") return false end

	local em

	if other_item then
		em = Inventory.MySQL.SwapInventories(it, other_item)
			:Then(function()
				if other_item then
					ActuallyMove(inv2, self, other_item, it:GetSlot())
				end
				ActuallyMove(self, inv2, it, slot)

				self:Emit("CrossInventoryMovedFrom", it, inv2, slot)
				inv2:Emit("CrossInventoryMovedTo", it, self, slot)
				return true
			end)
	else
		em = Inventory.MySQL.SetInventory(it, inv2, slot)
			:Then(function()
				ActuallyMove(self, inv2, it, slot)
				self:Emit("CrossInventoryMovedFrom", it, inv2, slot)
				inv2:Emit("CrossInventoryMovedTo", it, self, slot)
				return true
			end)
	end

	return em
end

function bp:LoadItems()
	return Inventory.MySQL.FetchPlayerItems(self, self:GetOwner())
end

--for adding an existing both in-game and in-sql item, use bp:AddItem(item)
--takes an existing item object and inserts it into the inventory as well as mysql

function bp:InsertItem(it, slot)
	slot = slot or it:GetSlot()

	if not slot then
		slot = self:GetFreeSlot()
		if not slot then print("Can't insert", it, "into", self, "cuz no slots") return false end
	end

	it:Insert(self)
	local insSlot

	local pr = Promise()

	if it:GetUID() then

		it:SetSlot(slot)

		insSlot = self:AddItem(it)
		if insSlot then
			self:AddChange(it, INV_ITEM_ADDED)
			pr:Resolve(it, insSlot)
		else
			pr:Reject(it, insSlot)
		end
	else
		it:Once("AssignUID", function()
			it:SetSlot(slot)
			insSlot = self:AddItem(it)
			if insSlot then
				self:AddChange(it, INV_ITEM_ADDED)
				pr:Resolve(it, insSlot)
			else
				pr:Reject(it, insSlot)
			end
		end)
	end

	return pr
end

local function canAdd(self, it, em, skipInv)
	local can, why, fmts = self:_CanAddItem(it, em, true, skipInv)

	if not can then
		if why then
			errorNHf(why, unpack(fmts or {}))
		end

		return false
	end

	return true
end

function bp:PickupItem(it, ignore_emitter, nochange)
	CheckArg(1, it, IsItem, "Item")

	local prs = {}

	--[[if not it:GetSlot() then
		it:SetSlot(self:GetFreeSlot())
	end]]

	if not canAdd(self, it, ignore_emitter, true) then
		return false, false
	end

	local left, itStk, newStk = Inventory.GetInventoryStackInfo(self, it)

	if not left and not itStk then

		-- item unstackable, just add it
		local slot = self:GetFreeSlot()
		if not slot then
			return false, false
		end

		it:TakeOut()
		it:SetSlot(slot)
		self:AddItem(it, ignore_emitter, nochange)

		local pr = Promise()
		pr:Resolve() -- instant resolve, nice

		return false, pr, {it}
	end

	for _, dat in ipairs(itStk) do
		local v, amt = unpack(dat)
		v:Stack(it)
	end

	local newIts = Inventory.CreateStackedItems(self, it, newStk)

	for k,v in ipairs(newIts) do
		prs[#prs + 1] = self:InsertItem(v)
	end

	if not self.ReadingNetwork then
		self:Emit("Change")
	end

	if left then
		it:SetAmount(left)
	else
		it:Delete()
	end

	local pr = Promise.OnAll(prs)

	return left, pr, newIts
end

--[[------------------------------]]
--	    Networking & shtuff
--[[------------------------------]]

function bp:SerializeItems(typ, key)
	local max_uid = 0
	local max_id = 0
	local amt = 0

	if typ == INV_NETWORK_FULLUPDATE or typ == nil then
		table.Empty(self.Changes)

		for k,v in pairs(self:GetItems()) do
			max_uid = math.max(max_uid, v:GetUID())
			max_id = math.max(max_id, v:GetIID())
			amt = amt + 1
		end

	elseif typ == INV_NETWORK_UPDATE then

		for k,v in pairs(self:GetItems()) do
			local req = false

			if self.Changes[v] then
				for k,v in pairs(self.Changes[v]) do
					if Inventory.RequiresNetwork[k] then req = true break end
				end
			end

			if not req then continue end

			max_uid = math.max(max_uid, v:GetUID())
			max_id = math.max(max_id, v:GetIID())
			amt = amt + 1
		end

	end

	local ns = Inventory.Networking.NetStack(max_uid, max_id)

	ns:WriteUInt(self.NetworkID, 16).InventoryNID = true

	if self.MultipleInstances then
		ns:WriteUInt(key, 16)
	end

	ns:WriteUInt(amt, 16).ItemsAmount = true

	if typ == INV_NETWORK_FULLUPDATE then
		for k,v in pairs(self:GetItems()) do
			v:Serialize(ns, typ)
			v:SetKnown(true)
		end

	elseif typ == INV_NETWORK_UPDATE then
		for k,v in pairs(self:GetItems()) do
			local req = false

			if self.Changes[v] then
				for k,v in pairs(self.Changes[v]) do
					if Inventory.RequiresNetwork[k] then
						req = true
						break
					end
				end
			end

			if not req then continue end

			v:Serialize(ns, typ)
			v:SetKnown(true)

			self.Changes[v] = nil
		end

	end


	return ns
end

function bp:WriteChanges(ns)
	local dels, moves, allits = {}, {}, {}
	local crossmove = {}

	local where = {
		[INV_ITEM_DELETED] = dels,
		[INV_ITEM_MOVED] = moves,
		[INV_ITEM_CROSSMOVED] = crossmove,

		[INV_ITEM_DATACHANGED] = false, -- ignore
		[INV_ITEM_ADDED] = false,
	}

	for item, enums in pairs(self.Changes) do
		for enum, _ in pairs(enums) do
			if not where[enum] then
				if where[enum] == nil then
					printf("Unknown change enum in %s! Ignoring... (%s: %q)", self.Name, item, enum == 2 and "2 (= added)" or enum)
				end
				continue
			end

			where[enum][#where[enum] + 1] = item
			allits[#allits + 1] = item
		end

		self.Changes[item] = nil
	end

	ns:Resize(allits)

	local hasdels = #dels > 0
	ns:WriteBool(hasdels).HasDeleted = true

	if hasdels then
		ns:WriteUInt(#dels, 16).DeletionAmt = true
		for k,v in ipairs(dels) do
			ns:WriteUID(v)
		end
	end

	local hascrossmoves = #crossmove > 0

	ns:WriteBool(hascrossmoves).HasCrossMoved = true

	if hascrossmoves then
		ns:WriteUInt(#crossmove, 16).CrossMovedAmt = true
		for k,v in ipairs(crossmove) do
			ns:WriteUID(v)
			ns:WriteSlot(v, true)
			--ns:WriteInventory(v:GetInventory())
		end
	end

	local hasmoves = #moves > 0

	ns:WriteBool(hasmoves).HasMoved = true

	if hasmoves then
		ns:WriteUInt(#moves, 16).MovedAmt = true
		for k,v in ipairs(moves) do
			ns:WriteUID(v)
			ns:WriteSlot(v, true)
		end
	end

end