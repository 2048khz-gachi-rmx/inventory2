
AddCSLuaFile()

local existed = Inventory

local verygood = Color(50, 150, 250)
local verybad = Color(240, 70, 70)



local InventoryDefine

function InventoryDefine()
	Inventory = {
		ItemObjects = {}, 				--Objects stores all metas and extension of the Item (the items owned by players and entities)

		BaseItemObjects = {},			--BaseItemObjects stores all metas and extension of the BaseItem (which all Items will use)
		BaseItems = {},					--stores the actual base item instances

		Inventories = {},				--inventory metas

		Util = {}, 						--utility functions

		Networking = { InventoryIDs = {} },

		IDConversion = {
			ToID = {},
			ToName = {}
		},

		Panels = {},

		Initted = (Inventory and Inventory.Initted) or false,

		Log = function(str, ...)
			MsgC(verygood, "[Inventory] ", color_white, str:format(...), "\n")
		end,

		LogError = function(str, ...)
			MsgC(verygood, "[Inventory ", verybad, "ERROR!", verygood, "] ", color_white, str:format(...), "\n")
		end,

		InDev = true
	}

	Inventory.Define = InventoryDefine

	Emitter.Make(Inventory)
end

if not Inventory then InventoryDefine() end
Inventory.Define = InventoryDefine

Items = Items

-- _sv are only included serverside
-- _extension are included by items manually
local function shouldIncludeItem(path)
	local is_sv = path:match("_sv")
	local ext = path:match("_extension")

	local cl, sv = true, true

	if is_sv then cl = false end
	if ext then cl = 1 sv = false end --extensions get included manually

	return cl, sv
end

--CLIENT: called instantly, no args
--SERVER: called after loading MySQL with db as the database


local function ContinueLoading(db)
	Inventory.Loading = true --prevent infinite looping in inventory/load.lua

	FInc.Recursive("inventory/shared/*", _SH)

	FInc.Coroutine("inventory/inv_meta/*", _SH, nil, shouldIncludeItem)
	FInc.Coroutine("inventory/base_items/*", _SH, nil, shouldIncludeItem)
	FInc.Coroutine("inventory/item_meta/*", _SH, nil, shouldIncludeItem)

	FInc.Recursive("inventory/server/*", _SV)
	FInc.Recursive("inventory/client/*", _CL)

	include("inv_items/load.lua") --that will handle the loading itself
	hook.Run("OnInventoryLoad")

	Inventory.Loading = false


	hook.Run("InventoryReady")
	Inventory.Initted = true

	hook.Remove("InventoryMySQLConnected", "ProceedInclude")
end

local LoadInventory

function LoadInventory(force)

	if force then
		Inventory.Define()
		Inventory.ReloadInventory = LoadInventory
		Inventory.Reload = LoadInventory
	end

	include("inventory/load.lua")
	AddCSLuaFile("inventory/load.lua")

	if SERVER then
		hook.Add("InventoryMySQLConnected", "ProceedInclude", ContinueLoading)
		include("inventory/inv_mysql.lua")
	else
		ContinueLoading()
	end

end

Inventory.ReloadInventory = LoadInventory
Inventory.Reload = LoadInventory

if not existed then
	hook.Add("InitPostEntity", "Inventory", LoadInventory)
else
	LoadInventory(true)
end
