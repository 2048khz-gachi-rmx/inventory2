if Inventory.Loading then return end --no infinite loops today sir

Inventory.MySQL = Inventory.MySQL or {}

local verygood = Color(50, 150, 250)
local verybad = Color(240, 70, 70)

Inventory.MySQL.Log = function(str, ...)
	MsgC(verygood, "[Inventory SQL] ", color_white, str:format(...), "\n")
end

Inventory.MySQL.LogError = function(str, ...)
	MsgC(verygood, "[Inventory SQL ", verybad, "ERROR!", verygood, "] ", color_white, str:format(...), "\n")
end

local ms = Inventory.MySQL
if not mysqloo then require("mysqloo") end

if not (ms.DB and ms.DB:status() == 0) then
	print("connecting to mysql")
	ms.INFO = {"127.0.0.1", "root", "31415", "inventory"}

	ms.DB = mysqloo.connect(unpack(ms.INFO))
	print('db initted')
	ms.DB.onConnected = function(self)
		print('connected!!!')
		hook.Run("InventoryMySQLConnected", self)
		print("ran hook okkk")
	end

	ms.DB.onConnectionFailed = function(self)
		ms.LogError("CONNECTION TO MYSQL DATABASE FAILED!!!")
		--hook.Run("InventoryMySQLConnected", self)
	end
	print("beginning connect")
	ms.DB:connect()

else
	hook.Run("InventoryMySQLConnected", ms.DB)
end