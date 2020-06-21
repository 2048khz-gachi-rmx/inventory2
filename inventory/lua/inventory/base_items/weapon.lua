--?
print("loaded weapon")
local eq = (hotloadedEquipment and Inventory.BaseItemObjects.Equipment) or Inventory.GetClass("base_items", "equipment")
local wep = eq:Extend("Weapon")

ChainAccessor(wep, "WeaponClass", "WeaponClass")


Inventory.RegisterClass("Weapon", wep, Inventory.BaseItemObjects)
