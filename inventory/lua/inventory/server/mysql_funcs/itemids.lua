do return end -- scrapped; i dont think you can make procedures with mysqloo lmfaooooooo

local ms = Inventory.MySQL
local db = ms.DB

-- format 1: type (PROCEDURE or FUNCTION)
-- format 2: name
-- format 3: arg list
-- format 4: function body

local format = [[DELIMITER $$
CREATE %s `%s`(
	%s
)
BEGIN
-- <Body>
%s
-- </Body>
END$$]]

-- everything here is unescaped; use carefully.

local function createProcedure(name, takes, body)
	local argList = isstring(takes) and takes or ""
	if istable(takes) then
		for name, type in pairs(takes) do
			argList = argList .. (name .. " " .. type:upper())
			if next(takes, name) then
				argList = argList .. ",\n	"
			end
		end
	end
	local qr = format:format("PROCEDURE", name, argList, body)
	print("Running query:", qr)

	local q = MySQLEmitter(db:query(body), true)
	q:Then(function(...)
		print("Created procedure `" .. name .. "` successfully!", ...)
	end):Catch(function(...)
		print("Am dead", ...)
	end)

	print("lets go")
end


createProcedure("InsertByIDInInventory", {
	id = "INT UNSIGNED",
	inv = "TEXT",
	puid = "BIGINT",
	slotid = "MEDIUMINT"
}, [[DECLARE uid INT UNSIGNED;
	INSERT INTO items(iid) VALUES(id);
    SET uid = last_insert_id();

	SET @t1 = CONCAT('INSERT INTO ', inv ,'(uid, puid, slotid) VALUES(', uid, ", ", puid,", ", slotid, ')' ); # oh my fucking god actually kill me
	PREPARE stmt3 FROM @t1;
	EXECUTE stmt3;
	DEALLOCATE PREPARE stmt3;

	SELECT uid;]])