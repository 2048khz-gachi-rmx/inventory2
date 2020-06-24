--

local eq = Inventory.GetClass("item_meta", "equippable")
local wep = Inventory.ItemObjects.Weapon or eq:Extend("Weapon")

BaseItemAccessor(wep, "WeaponClass", "WeaponClass")
function wep:Equip(ply, slot)
	local mem = eq.Equip(self, ply, slot)

	ply:Give(self:GetWeaponClass())
	print("weapon: equipping too")


	return mem
end

local allowed = table.KeysToValues({"primary", "secondary", "utility"})

wep:On("CanEquip", "WeaponCanEquip", function(self, ply, slot)
	local slotName = slot.slot

	local can, why = Inventory.CanEquipInSlot(self, slot)
	if can == false then return can, why end

	if not allowed[slotName] then return false, ("Not a possible weapon slot: '%s'"):format(slotName) end
	if self:GetInventory() and self:GetInventory():GetOwner() ~= ply then return false, ("Player is not owner: '%s' vs '%s'"):format(tostring(self:GetOwner()), tostring(ply)) end
end)

wep:Register()