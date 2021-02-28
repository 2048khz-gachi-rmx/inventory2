-- SELECT its.iid, its.uid, its.data, inv.slotid FROM items

local q = [[CREATE TABLE IF NOT EXISTS `inventory`.`items` (
  `uid` int NOT NULL AUTO_INCREMENT,
  `iid` int NOT NULL,
  `data` json DEFAULT NULL,
  PRIMARY KEY (`uid`),
  UNIQUE KEY `uid_UNIQUE` (`uid`)
)
]]

local ms = Inventory.MySQL
local db = ms.DB
local qry = db:query(q)

ms.RegisterState("items_table")

local em = ms.StateSetQuery( MySQLEmitter(qry, true):Then(function(a, b, c)
	ms.Log("Created `Items` table successfully.")
end):Catch(function(_, err)
	ms.LogError("Failed to create `Items` table! [[\n\n%s\n\n]]", err)
end), "items_table" )