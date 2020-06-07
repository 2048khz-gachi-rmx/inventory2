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

Inventory.RequiresNetwork = {
	[INV_ITEM_ADDED] = true,
	[INV_ITEM_DATACHANGED] = true,
}