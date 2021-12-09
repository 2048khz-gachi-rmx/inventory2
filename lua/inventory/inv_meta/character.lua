local bp = Inventory.GetClass("inv_meta", "backpack")
if not bp then error("Something went wrong while loading Character inventory: backpack is missing.") return end

local char = Inventory.Inventories.Character or bp:extend()

char.SQLName = "ply_char"
char.NetworkID = 4
char.Name = "Character"
char.MaxItems = 50
char.IsCharacterInventory = true

char.ActionCanCrossInventoryFrom = CLIENT
char.ActionCanCrossInventoryTo = CLIENT

char:On("CanOpen", "NoOpen", function()
	return false
end)

char:On("CanAddItem", "ManualOnly", function(self, it)
	return self.Allowed[it:GetUID()] -- you can only add items here through the :Equip() method
end)

char:On("CanMoveTo", "EquipOnly", function(self, it, slot)
	return self.Allowed[it:GetUID()]
end)

char:On("CanMoveFrom", "UnequipOnly", function(self, it, slot)
	return self.Allowed[it:GetUID()]
end)

char:On("CanMoveItem", "FittingOnly", function(self, it, slot)
	local can, why = Inventory.CanEquipInSlot(it, slot)
	if can == false then return can, why end
end)

char:On("CanCreateItem", "ManualOnly", function(self, iid, dat, slot)
	return false
end)

function char:Initialize()
	self.Slots = {}
	self.Allowed = {}
end

function char:Unequip(it, slot, inv)
	print("unequipping", it)
	if not IsInventory(inv) then error("Unequip where dude") return end

	--local it = self.Slots[slot]
	if not IsItem(it) then error("What are you unequipping dude") return end

	local mem = self:CrossInventoryMove(it, inv, slot)
	self.Allowed[it:GetUID()] = nil

	return mem
end

function char:Equip(it, slot)
	print("equipping", it)

	if IsItem(self.Slots[slot]) then
		-- item there already; unequip and it'll make us crossinv move
		self.Allowed[it:GetUID()] = true
		local mem = self:Unequip(self.Slots[slot], it:GetSlot(), it:GetInventory()) --switch items places
		self.Slots[slot] = it

		return mem
	end

	self.Allowed[it:GetUID()] = true

	local inv = it:GetInventory()
	local mem = inv:CrossInventoryMove(it, self, slot)

	self.Slots[slot] = it
	--self:AddChange(it, INV_ITEM_ADDED)
	return mem
end

char:Register()