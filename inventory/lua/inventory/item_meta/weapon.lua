--

local eq = Inventory.GetClass("item_meta", "equippable")
local wep = Inventory.ItemObjects.Weapon or eq:Extend("Weapon")

function wep:Equip(ply)
	eq.Equip(self, ply)
	print("weapon: equipping too")
end

wep:Register()