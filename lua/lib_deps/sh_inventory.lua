
AddCSLuaFile()

local InventoryDefine

local shortRealm = SERVER and "SV" or "CL"
local logName = "Inv-" .. shortRealm
local logCol = CLIENT and Color(255, 195, 50) or Color(70, 200, 250)

local verybad = Color(210, 70, 70)

function InventoryDefine()

	-- this allows us to get baseitems using either their name or number
	local BaseItemsTable = setmetatable({}, {__index = function(self, key)
		if isnumber(key) then

			local it = self[Inventory.Util.ItemIDToName(key)]
			self[key] = it --alias it straight away

			return it
		end
	end})

	Inventory = {
		ItemObjects = {}, 				-- Objects stores all metas and extension of the Item (the items owned by players and entities)
		ItemPool = WeakTable("v"), 		-- pool of itemUID : itemObj
		BaseItemObjects = {},			-- BaseItemObjects stores all metas and extension of the BaseItem (which all Items will use)
		BaseItems = BaseItemsTable,					-- stores the actual base item instances

		Inventories = {},				-- inventory metas

		Util = {}, 						-- utility functions

		Networking = { InventoryIDs = {} },

		IDConversion = {
			ToID = {},
			ToName = {}
		},

		Panels = {},

		Initted = false,

		Log = Logger(logName, logCol),

		LogError = function(str, ...)
			MsgC(logCol, "[" .. logName, verybad, " ERROR!", logCol, "] ", color_white, str:format(...), "\n")
		end,

		Included = {},

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
-- this function assumes inclusion realm is _SH

local fResolver = FInc.RealmResolver()
	--:SetVerbose()
	:SetDefault(true)

local function shouldIncludeItem(path, ...)
	if Inventory.Included[path] then return false, false end --something before us already included it, don't include again

	return fResolver(path, ...)
end

local function shouldIncludeCore(path, ...)
	return fResolver(path, ...)
end

local states = {}
local requiredStates = {
	["InventoryItemIDsReceived"] 	= SERVER,
	["InventoryActionsLoaded"] 		= SERVER,
	["InventoryMySQLInitialized"]	= SERVER
}
_RequiredStates = requiredStates
local function addState(k)
	states[k] = true
	requiredStates[k] = nil

	if table.IsEmpty(requiredStates) then
		hook.Run("InventoryReady")
		Inventory.Initted = true
	end
end

local function listenState(k)
	if requiredStates[k] == false then -- not our realm; just mark it as 'loaded'
		addState(k)
		return
	end

	hook.Add(k, "InventoryTrackLoadState", Curry(addState, k))
end

local function ContinueLoading()
	for k,v in pairs(requiredStates) do
		listenState(k)
	end

	-- loading core
	FInc.Recursive("inventory/shared/*", _SH, shouldIncludeCore)

	FInc.Recursive("inventory/inv_meta/*", _SH, shouldIncludeItem)
	FInc.Recursive("inventory/base_items/*", _SH, shouldIncludeItem)
	FInc.Recursive("inventory/item_meta/*", _SH, shouldIncludeItem)

	FInc.Recursive("inventory/server/*", _SV, shouldIncludeCore)
	FInc.Recursive("inventory/client/*", _CL, shouldIncludeCore)

	-- loading extensions
	FInc.Recursive("inventory/misc/*", _SH, FInc.RealmResolver())

	-- loading items
	include("inv_items/load.lua") --that will handle the loading itself

	FInc.Recursive("inventory/deps/*", _SH, FInc.RealmResolver())
end

local LoadInventory --pre-definition

function LoadInventory(force)

	if force then
		Inventory.Define()
		Inventory.ReloadInventory = LoadInventory
		Inventory.Reload = LoadInventory
	end

	Inventory.Included = {}

	include("inventory/load.lua")
	AddCSLuaFile("inventory/load.lua")

	if SERVER then
		include("inventory/inv_mysql.lua")
	end

	ContinueLoading()
end

local function reload()
	return LoadInventory(true)
end

Inventory.ReloadInventory = reload
Inventory.Reload = reload


function Inventory.DirtyReload()
	Inventory = nil
	include("lib_deps/sh_inventory.lua")
end

LibItUp.OnInitEntity(LoadInventory)

--[[
if not existed then
	hook.Add("InitPostEntity", "Inventory", LoadInventory)
else
	LoadInventory(true)
end
]]
