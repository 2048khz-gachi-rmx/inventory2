--

local eq = Inventory.GetClass("item_meta", "equippable")
local wep = Inventory.ItemObjects.Weapon

function wep:Equip(ply, slot)
	local mem = eq.Equip(self, ply, slot)
	self:UseCharge(ply)
	return mem
end

function wep:UseCharge(ply)
	local new = ply:Give(self:GetWeaponClass())
	if new ~= NULL then
		self:SetUses(self:GetUses() - 1)

		if self:GetUses() == 0 then
			self:Delete()
		end

		hook.NHRun("InventoryWeaponGiven", self, ply, new)
	end
end

hook.Add("PlayerLoadout", "InventoryWeapons", function(ply)
	local inv = Inventory.GetEquippableInventory(ply)
	local slots = Inventory.EquipmentSlots
	local its = inv:GetSlots()

	local used = false

	for slot, dat in ipairs(slots) do
		if not its[slot] then continue end

		local typ = dat.type
		if typ ~= "Weapon" then continue end

		its[slot]:UseCharge(ply)
		used = true
	end

	if used then
		ply:RequestUpdateInventory(inv)
	end
end)

hook.Add("InventoryWeaponGiven", "WeaponData", function(itm, ply, wep)
	local wdt = Inventory.WeaponData
	local wd = wdt.Get(itm:GetUID()) or wdt.Object:new(itm:GetUID())

	wd:SetQuality(itm:GetQuality())
	wd:SetMods(itm:GetModifiers())
	wd:SetStats(itm:GetStats())

	wd:SetWeapon(wep)
end)