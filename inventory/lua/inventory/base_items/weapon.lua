--?

local eq = Inventory.GetClass("base_items", "equipment")
local wep = eq:Extend("Weapon", "Weapon")

ChainAccessor(wep, "WeaponClass", "WeaponClass")

wep:Register()
--Inventory.RegisterClass("Weapon", wep, Inventory.BaseItemObjects)
