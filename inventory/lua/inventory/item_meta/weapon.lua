--

local eq = Inventory.GetClass("item_meta", "equippable")
local wep = eq:Extend("Weapon")

function wep:Equip()

end

wep:Register()