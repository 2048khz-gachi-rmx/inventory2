--[[
	Slot: {
		slot = "internal_name",
		name = "Fancy Name",
		type = "Weapon", -- optional; what baseitems can possibly go there
							if you set type 'weapon' then 'equipment' can't go there, and vice versa
		id = 1, --number
		side = LEFT / RIGHT -- to which side the equipment button will stick?
							-- this isn't docking; calculations are custom
	}
]]

Inventory.EquipmentSlots = {
	{slot = "head", name = "Head", type = "Equipment", side = LEFT},
	{slot = "body", name = "Body", type = "Equipment", side = LEFT},
	{slot = "legs", name = "Legs", type = "Equipment", side = LEFT},
	{slot = "primary", name = "Primary", type = "Weapon", side = RIGHT},
	{slot = "secondary", name = "Secondary", type = "Weapon", side = RIGHT},
}

--basically backwards; ["head"] = 1, ...
--also assigns 'id' key
Inventory.EquipmentIDs = {}

for k,v in ipairs(Inventory.EquipmentSlots) do
	Inventory.EquipmentIDs[v.slot] = v
	Inventory.EquipmentIDs[k] = v
	Inventory.EquipmentIDs[v.name] = v
	v.id = k
end

function Inventory.EquippableID(what)
	return Inventory.EquipmentIDs[what] and Inventory.EquipmentIDs[what].id
end