--[[----------------------------------------]]

--	  Shared enums, mostly for networking

--[[----------------------------------------]]



--[[---------------------------------------------]]

--  Inventory Actions (use item, move item, etc.)

--[[---------------------------------------------]]


INV_ACTION_MOVE = 0
INV_ACTION_USE = 1
INV_ACTION_SPLIT = 2
INV_ACTION_MERGE = 3
INV_ACTION_DELETE = 4
INV_ACTION_CROSSINV_MOVE = 5 -- cross-inventory move, not implemented YET
INV_ACTION_CROSSINV_SPLIT = 6 -- also not implemented
INV_ACTION_EQUIP = 7 

--[[------------------------------]]

--	  Inventory networking types

--[[------------------------------]]

INV_NETWORK_FULLUPDATE = 0
INV_NETWORK_UPDATE = 1

--[[------------------------------]]

--	  Item statuses

--[[------------------------------]]

INV_ITEM_DELETED = 0
INV_ITEM_MOVED = 1
INV_ITEM_ADDED = 2
INV_ITEM_DATACHANGED = 3
INV_ITEM_CROSSMOVED = 4

Inventory.RequiresNetwork = {
	[INV_ITEM_ADDED] = true,
	[INV_ITEM_DATACHANGED] = true,
}


--[[------------------------------]]

--	  		  Equipment

--[[------------------------------]]

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
	v.id = k
end