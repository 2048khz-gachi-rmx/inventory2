--?

local eq = Inventory.GetClass("base_items", "equipment")
local wep = Inventory.BaseItemObjects.Weapons or eq:callable("Weapon", "Weapon")

wep.Uses = 150

ChainAccessor(wep, "WeaponClass", "WeaponClass")

wep:Register()
wep:NetworkVar("UInt", "Uses", 16)
--Inventory.RegisterClass("Weapon", wep, Inventory.BaseItemObjects)
