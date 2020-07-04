if CLIENT then error("HOW") end
local bp = Inventory.Inventories.Backpack

function bp:NewItem(iid, cb, slot, dat)
	cb = cb or BlankFunc

	local can = self:Emit("CanCreateItem", iid, dat, slot)
	if can == false then return false end

	slot = slot or self:GetFreeSlot()
	if not slot or slot > self.MaxItems then errorf("Didn't find a slot where to put the item or it was above MaxItems! (%s > %d)", slot, self.MaxItems) return end

	local its, left = Inventory.CheckStackability(self, iid, cb, slot, dat)

	if istable(its) then

		for k,v in ipairs(its) do
			v:Insert(self)
			v:Once("AssignUID", function()
				self:AddItem(v, true)
			end)
			self:AddChange(v, INV_ITEM_ADDED)
		end

		return left
	end

	if its == true then return end

	local it = Inventory.NewItem(iid, self)
	it:SetSlot(slot)

	it:Insert(self)

	if it:GetUID() then
		self:AddItem(it, true)
		cb(it, slot)
		error("INSTANT FIRE???")
	else

		it:Once("AssignUID", function()
			self:AddItem(it, true)
			cb(it, slot)
		end)

	end

end



function bp:CrossInventoryMove(it, inv2, slot)
	if it:GetInventory() ~= self then errorf("Can't move an item from an inventory which it doesn't belong to! (item) %q vs %q (self)", it:GetInventory(), self) return end

	slot = slot or inv2:GetFreeSlot()
	if not slot then print("Can't cross-inventory-move cuz no slot", slot) return end

	--check if inv2 can accept cross-inventory item
	local can = inv2:Emit("CanMoveTo", it, self)
	if can == false then return false end

	--check if inv1 can give out the item
	can = self:Emit("CanMoveFrom", it, inv2)
	if can == false then return false end

	--check if inv2 can add an item to itself
	can = inv2:Emit("CanAddItem", it, it:GetUID())
	if can == false then return false end


	local em = Inventory.MySQL.SetInventory(it, inv2, slot)

	self:RemoveItem(it)
	inv2:AddItem(it, true)

	--has it moved successfully 100%?
	if inv2.Changes[it] == INV_ITEM_ADDED then
		self:AddChange(it, INV_ITEM_CROSSMOVED)
		inv2.Changes[it] = nil
	end

	return em
end

--for adding an existing both in-game and in-sql item, use bp:AddItem(item)
--takes an existing item and inserts it into the inventory as well as mysql

function bp:InsertItem(it, slot, cb)
	cb = cb or BlankFunc

	if not slot then
		slot = self:GetFreeSlot()
		if not slot then print("Can't insert", it, "into", self, "cuz no slots") return false end
	end

	it:SetSlot(slot)

	local sqlemit = it:Insert(self)

	if it:GetUID() then
		self:AddItem(it)
		cb(it, slot)
		self:AddChange(it, INV_ITEM_ADDED)
	else

		it:Once("AssignUID", function()
			self:AddItem(it)
			cb(it, slot)
			self:AddChange(it, INV_ITEM_ADDED)
		end)

	end

end

--[[------------------------------]]
--	    Networking & shtuff
--[[------------------------------]]

function bp:SerializeItems(typ)
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
			if not Inventory.RequiresNetwork[self.Changes[v]] then continue end
			max_uid = math.max(max_uid, v:GetUID())
			max_id = math.max(max_id, v:GetIID())
			amt = amt + 1
		end

	end

	local ns = Inventory.Networking.NetStack(max_uid, max_id)

	ns:WriteUInt(self.NetworkID, 16).InventoryNID = true
	ns:WriteUInt(amt, 16).ItemsAmount = true


	if typ == INV_NETWORK_FULLUPDATE then
		for k,v in pairs(self:GetItems()) do
			v:Serialize(ns, typ)
			v:SetKnown(true)
		end

	elseif typ == INV_NETWORK_UPDATE then
		for k,v in pairs(self:GetItems()) do
			if not Inventory.RequiresNetwork[self.Changes[v]] then continue end
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

	for item, enum in pairs(self.Changes) do
		if not where[enum] then printf("Unknown change enum in %s! Ignoring... (%s: %q)", self.Name, item, enum) continue end
		where[enum][#where[enum] + 1] = item
		allits[#allits + 1] = item

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

	local hasmoves = #moves > 0

	ns:WriteBool(hasmoves).HasMoved = true

	if hasmoves then
		ns:WriteUInt(#moves, 16).MovedAmt = true
		for k,v in ipairs(moves) do
			ns:WriteUID(v)
			ns:WriteSlot(v)
		end
	end

	local hascrossmoves = #crossmove > 0

	ns:WriteBool(hascrossmoves).HasCrossMoved = true
	if hascrossmoves then
		ns:WriteUInt(#crossmove, 16).CrossMovedAmt = true
		for k,v in ipairs(crossmove) do
			ns:WriteUID(v)
			ns:WriteInventory(v:GetInventory())
		end
	end
end