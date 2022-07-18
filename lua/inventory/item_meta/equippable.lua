--

local uq = Inventory.GetClass("item_meta", "unique_item")
local gen = Inventory.GetClass("item_meta", "generic_item")
local eq = Inventory.ItemObjects.Equippable or uq:Extend("Equippable")

eq.IsEquippable = true

-- give these functions to generic so all the other items
-- also have this method (to return nil)
BaseItemAccessor(gen, "IsEquippable", "Equippable")


BaseItemAccessor(eq, "EquipSlot", "EquipSlot")

ChainAccessor(eq, "Equipped", "Equipped")
eq.IsEquipped = eq.GetEquipped

function eq:Unequip(ply, slot, intoInv)
	local char = Inventory.GetEquippableInventory(ply)
	if not char then errorf("What the fuck can't equip on %s cuz no character inventory", ply) end

	local ok = char:Unequip(self, slot, intoInv)

	if ok then
		self:SetEquipped(false)
	end

	return ok
end

function eq:Equip(ply, slot)
	local char = Inventory.GetEquippableInventory(ply)
	if not char then errorf("What the fuck can't equip on %s cuz no character inventory", ply) end

	local ok = char:Equip(self, slot)

	if ok then
		self:SetSlot(slot)
		self:SetEquipped(true)
	end

	return ok
end


eq:Register()