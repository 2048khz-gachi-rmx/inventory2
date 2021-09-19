local bp = Inventory.Inventories.Backpack
ChainAccessor(bp, "LastResync", "LastResync")
--[[
	returns a promise (and maybe a number)
		- resolved with a table of items = those items were added
		- resolved with false and a table of items = those items got stacked into

	the maybe number is the amount of items left which couldnt be stacked in anywhere
]]

function bp:NewItem(iid, cb, slot, dat, nostack, cbanyway)
	if not isstring(iid) and not isnumber(iid) then
		errorf("Attempted to create item with IID: %s (%s)", iid, type(iid))
		return
	end

	cb = cb or BlankFunc

	local pr = Promise()

	local can, why = self:Emit("CanCreateItem", iid, dat, slot)
	if can == false then return false, ("Cannot create item (%s)"):format(why or "emit returned false") end


	if not nostack then
		local its, left = Inventory.CheckStackability(self, iid, cb, dat)

		-- table of new items given; now to insert them in SQL
		if istable(its) then
			local prs = {}
			for k,v in ipairs(its) do
				local newPr = Promise()
				table.insert(prs, newPr)

				if self.UseSQL ~= false then
					v:Insert(self)
					v:On("AssignUID", "InsertIntoInv", function(v, uid)
						self:AddItem(v, true)
						self:AddChange(v, INV_ITEM_ADDED)
						cb(v, slot)
						newPr:Resolve(v)
					end)
				else
					newPr:Resolve(v)
					cb(v, slot)
				end
			end


			return Promise.OnAll(prs), left
		end

		if its == true then
			if cbanyway then cb() end
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
		it:Once("AssignUID", function()
			self:AddItem(it, true)
			cb(it, slot)
			pr:Resolve({it})
		end)
	else
		cb(it, slot)
		pr:Resolve({it})
	end

	return pr, 0
	--[[else
		self:AddItem(it, true)
		cb(it, slot)
	end]]


end

function bp:NewItemNetwork(who, iid, cb, slot, dat, nostack, cbanyway)

	if isnumber(who) or isstring(who) then
		-- shift args 1 up
		cbanyway = nostack
		nostack = dat
		dat = slot
		slot = cb
		cb = iid
		iid = who

		who = self:GetOwner()
	end

	local real_cb = function(...)
		if cb then cb(...) end

		if IsValid(self:GetOwner()) then
			Inventory.Networking.NetworkInventory(who, self, INV_NETWORK_UPDATE)
		end
	end

	local pr = self:NewItem(iid, real_cb, slot, dat, nostack, cbanyway)

	-- true is the only case where we need to call cb and network manually

	pr:Then(function()
		if cbanyway then
			real_cb() --already takes care of networking
		elseif IsValid(self:GetOwner()) then
			Inventory.Networking.NetworkInventory(who, self, INV_NETWORK_UPDATE)
		end
	end)

	return pr
end

-- can you move FROM this inv?
function bp:CanCrossInventoryMove(it, inv2, slot)
	-- check if they have that slot available

	if slot and inv2:IsSlotLegal(slot) == false then return false end

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
	local em = Inventory.MySQL.SetInventory(it, inv2, slot)

	inv1:RemoveItem(it, true, true) -- don't write the change 'cause we have crossmoves as a separate change
	it:SetSlot(slot)
	inv2:AddItem(it, true, true) -- same shit

	inv2:AddChange(it, INV_ITEM_CROSSMOVED)

	return em
end

-- move from bp to inv2
function bp:CrossInventoryMove(it, inv2, slot)
	if it:GetInventory() ~= self then errorf("Can't move an item from an inventory which it doesn't belong to! (item) %q vs %q (self)", it:GetInventory(), self) return end

	slot = slot or inv2:GetFreeSlot()
	if not slot then print("Can't cross-inventory-move cuz no slot", slot) return false end
	if not inv2:IsSlotLegal(slot) then printf("Attempted to move item out of inventory bounds (%s > %s)", slot, inv2.MaxItems) return end

	local other_item = inv2:GetItemInSlot(slot)

	if other_item then
		if not inv2:CanCrossInventoryMove(other_item, self, it:GetSlot()) then print(inv2, "#1 doesn't allow CIM") return false end
	end

	if not self:CanCrossInventoryMove(it, inv2) then print(self, "#2 doesn't allow CIM") return false end

	if other_item then
		ActuallyMove(inv2, self, other_item, it:GetSlot())
	end
	local em = ActuallyMove(self, inv2, it, slot)

	self:Emit("CrossInventoryMovedFrom", it, inv2, slot)
	inv2:Emit("CrossInventoryMovedTo", it, self, slot)

	return em
end

--for adding an existing both in-game and in-sql item, use bp:AddItem(item)
--takes an existing item object and inserts it into the inventory as well as mysql

function bp:InsertItem(it, slot, cb)
	cb = cb or BlankFunc

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
			cb(it, insSlot)
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
				cb(it, insSlot)
				self:AddChange(it, INV_ITEM_ADDED)
				pr:Resolve(it, insSlot)
			else
				pr:Reject(it, insSlot)
			end
		end)
	end

	return pr
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
	}

	for item, enums in pairs(self.Changes) do
		for enum, _ in pairs(enums) do
			if not where[enum] then
				printf("Unknown change enum in %s! Ignoring... (%s: %q)", self.Name, item, enum == 2 and "2 (= added)" or enum)
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
			ns:WriteSlot(v)
			--ns:WriteInventory(v:GetInventory())
		end
	end

	local hasmoves = #moves > 0

	ns:WriteBool(hasmoves).HasMoved = true

	if hasmoves then
		ns:WriteUInt(#moves, 16).MovedAmt = true
		for k,v in ipairs(moves) do
			ns:WriteUID(v)
			ns:WriteSlot(v)
		end
	end

end