--

local gen = Inventory.GetClass("item_meta", "generic_item")
local eq = gen:Extend("Equippable")

eq.IsEquippable = true

-- give these functions to generic so all the other items
-- also have this method (to return nil)

BaseItemAccessor(gen, "IsEquippable", "Equippable")

BaseItemAccessor(eq, "EquipSlot", "EquipSlot")



eq:Register()