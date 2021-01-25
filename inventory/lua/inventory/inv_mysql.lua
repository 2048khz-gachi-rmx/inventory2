if Inventory.Loading then return end --no infinite loops today sir

Inventory.MySQL = Inventory.MySQL or Emitter:new()

local verygood = Color(50, 150, 250)
local verybad = Color(240, 70, 70)

Inventory.MySQL.Log = function(str, ...)
	MsgC(verygood, "[Inventory SQL] ", color_white, str:format(...), "\n")
end

Inventory.MySQL.LogError = function(str, ...)
	MsgC(verygood, "[Inventory SQL ", verybad, "ERROR!", verygood, "] ", color_white, str:format(...), "\n")
end

local ms = Inventory.MySQL
ms._Connected = false
if not mysqloo then require("mysqloo") end

local connectFunc

local incHelper = function()
	include("server/mysql_init_extension/_init.lua")
end

function connectFunc(whomst)
	if whomst and IsPlayer(whomst) and not whomst:IsSuperAdmin() then return false end

	ms.INFO = {"127.0.0.1", "root", "31415", "inventory"}

	ms.DB = mysqloo.connect(unpack(ms.INFO))

	ms.DB.onConnected = function(self)
		ms.Log("Connected successfully!")
		ms._Connected = true
		hook.Run("InventoryMySQLConnected", self)
	end

	ms.DB.onConnectionFailed = function(self, ...)
		ms.LogError("CONNECTION TO MYSQL DATABASE FAILED!!!")
		ms.LogError("Do `inventory_reconnect` if you want to try again.")
		ms.LogError(...)
		concommand.Add("inventory_reconnect", connectFunc)
	end

	ms.DB:connect()
	incHelper()
end

ms.ReconnectDB = connectFunc

if not (ms.DB and ms.DB:status() == 0) then
	connectFunc()
else
	ms._Connected = true
	incHelper()
	hook.Run("InventoryMySQLConnected", ms.DB)
end