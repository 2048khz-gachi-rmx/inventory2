-- SELECT its.iid, its.uid, its.data, inv.slotid FROM items

local queries = {}
local ms = Inventory.MySQL
local db = ms.DB

local function query(q, suc, fail)
	local em = ms.StateSetQuery( MySQLEmitter(db:query(q), true), "items_table" )

	em:Then(function(a, b, c)
		if suc then
			ms.Log(suc)
		end
	end, function(_, err)
		if fail then
			ms.LogError(fail, err)
		else
			ms.LogError("Generic error: [[\n\n%s\n\n]]", err)
		end
	end)

	table.insert(queries, em)
end


--------------------------------

local q = [[CREATE TABLE IF NOT EXISTS `items` (
	`uid` int NOT NULL AUTO_INCREMENT,
	`iid` int NOT NULL,
	`data` json DEFAULT NULL,
	PRIMARY KEY (`uid`),
	UNIQUE KEY `uid_UNIQUE` (`uid`)
)
]]

query(q, "Created `Items` table successfully.", "Failed to create `Items` table! [[\n\n%s\n\n]]")

q = [[CREATE TABLE IF NOT EXISTS `itemids` (
	`id` int NOT NULL AUTO_INCREMENT,
	`name` varchar(254) NOT NULL,
	PRIMARY KEY (`id`),
	UNIQUE KEY `id_UNIQUE` (`id`),
	UNIQUE KEY `name_UNIQUE` (`name`)
)]]

query(q, "Created ItemIDs table successfully.", "Failed to create ItemIDs table! [[\n\n%s\n\n]]")

--------------------------------

local amt = #queries

ms.RegisterState("items_table")

for k,v in ipairs(queries) do
	v:Then(function()
		amt = amt - 1

		if amt == 0 then
			ms.SetState("items_table", true)
			Inventory.MySQL.Log("All item tables ready!")
		end
	end)
end

