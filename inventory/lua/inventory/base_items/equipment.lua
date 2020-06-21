local gen = Inventory.GetClass("base_items", "generic_item")
local eq = gen:Extend("Equipment")

eq.IsEquippable = true

ChainAccessor(eq, "IsEquippable", "Equippable")
ChainAccessor(eq, "EquipSlot", "EquipSlot")

eq:Register(0)
