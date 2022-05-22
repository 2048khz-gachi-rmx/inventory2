local bp = Inventory.GetClass("inv_meta", "backpack")
if not bp then error("Something went wrong while loading Character inventory: backpack is missing.") return end

local char = Inventory.Inventories.Character or bp:extend()

char.Name = "Character"

char.SQLName = "ply_char"
char.NetworkID = 4
char.MaxItems = 50
char.IsCharacterInventory = true

char.ActionCanCrossInventoryFrom = CLIENT
char.ActionCanCrossInventoryTo = CLIENT

char:On("CanOpen", "NoOpen", function()
	return false
end)

char:On("CanAddItem", "ManualOnly", function(self, it)
	return self.Allowed[it:GetNWID()] -- you can only add items here through the :Equip() method
end)

char:On("CanMoveTo", "EquipOnly", function(self, it, slot)
	return self.Allowed[it:GetNWID()]
end)

char:On("CanMoveFrom", "UnequipOnly", function(self, it, slot)
	return self.Allowed[it:GetNWID()]
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
	if not IsInventory(inv) then error("Unequip where dude") return false end
	if not IsItem(it) then error("What are you unequipping dude") return false end

	self:CrossInventoryMove(it, inv, slot)
	self.Allowed[it:GetNWID()] = nil

	return true
end

function char:Equip(it, slot)
	if IsItem(self.Slots[slot]) then
		-- item there already; unequip and it'll make us crossinv move
		self.Allowed[it:GetNWID()] = true
		self:Unequip(self.Slots[slot], it:GetSlot(), it:GetInventory()) --switch items places
		self.Slots[slot] = it

		return true
	end

	self.Allowed[it:GetNWID()] = true

	local inv = it:GetInventory()
	inv:CrossInventoryMove(it, self, slot)

	self.Slots[slot] = it
	return true
end

char:Register()