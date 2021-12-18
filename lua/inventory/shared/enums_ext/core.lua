--[[---------------------------------------------]]
--  Inventory Actions (use item, move item, etc.)
--[[---------------------------------------------]]

INV_ACTION_MOVE = 0
INV_ACTION_USE = 1
INV_ACTION_SPLIT = 2
INV_ACTION_MERGE = 3
INV_ACTION_DELETE = 4
INV_ACTION_CROSSINV_MOVE = 5
INV_ACTION_CROSSINV_MERGE = 6
INV_ACTION_CROSSINV_SPLIT = 7
INV_ACTION_EQUIP = 8
INV_ACTION_RESYNC = 9
INV_ACTION_PICKUP = 10

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


Inventory.DropCleanupTime = 120