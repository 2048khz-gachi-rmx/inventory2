--

local gen = Inventory.GetClass("item_meta", "generic_item")
local eq = Inventory.ItemObjects.Equippable or gen:Extend("Equippable")

eq.IsEquippable = true

-- give these functions to generic so all the other items
-- also have this method (to return nil)

BaseItemAccessor(gen, "IsEquippable", "Equippable")

BaseItemAccessor(eq, "EquipSlot", "EquipSlot")

function eq:Equip(ply, slot)
	local char = ply.Inventory.Character
	if not char then errorf("What the fuck can't equip on %s cuz no character inventory", ply) end

	local mem = char:Equip(self, slot)
	print("Equipped", self, slot, " but serverside")
	return mem
end


eq:Register()