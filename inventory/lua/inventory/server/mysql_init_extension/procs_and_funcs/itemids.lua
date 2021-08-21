local ms = Inventory.MySQL
local db = ms.DB

local queries = {}

queries[#queries + 1] = ms.CreateProcedure("InsertByIDInInventory",

	LibItUp.SQLArgList()
		:AddArg("id", "INT UNSIGNED")
		:AddArg("inv", "TEXT")
		:AddArg("puid", "BIGINT"),

[[	DECLARE uid INT UNSIGNED;
	INSERT INTO items(iid) VALUES(id);
    SET uid = last_insert_id();

	SET @t1 = CONCAT('INSERT INTO ', inv ,'(uid, puid) VALUES(', uid, ", ", puid, ')' ); # oh my fucking god actually kill me
	PREPARE stmt3 FROM @t1;
	EXECUTE stmt3;
	DEALLOCATE PREPARE stmt3;

	SELECT uid;]])


queries[#queries + 1] = ms.CreateProcedure("InsertByItemNameInInventory",

LibItUp.SQLArgList()
	:AddArg("itemname",		"VARCHAR(254)")
	:AddArg("inv",  		"TEXT")
	:AddArg("puid",			"BIGINT"),

[[	DECLARE uid INT UNSIGNED;
    DECLARE iid INT UNSIGNED;
    SELECT id INTO iid FROM itemids WHERE name = itemname;
	INSERT INTO items(iid) VALUES(iid);
    SET uid = last_insert_id();

	SET @t1 = CONCAT('INSERT INTO ', inv ,'(uid, puid)
		VALUES(', uid, ", ", puid,')' ); # oh my fucking god actually kill me
	PREPARE stmt3 FROM @t1;
	EXECUTE stmt3;
	DEALLOCATE PREPARE stmt3;

	SELECT uid;
]])


queries[#queries + 1] = ms.CreateFunction("GetBaseItemID",

LibItUp.SQLArgList()
	:AddArg("comp_name", "VARCHAR(254)"),

"RETURNS INT MODIFIES SQL DATA DETERMINISTIC",

[[	DECLARE ret INT DEFAULT NULL;
    SELECT id INTO ret FROM itemids WHERE name = comp_name;

    IF ( isnull(ret) ) THEN
		INSERT INTO `itemids`(name) VALUES(comp_name);
		RETURN LAST_INSERT_ID();
	END IF;

	RETURN ret;]])

---------------------
ms.RegisterState("procedures")

local amt = #queries
for k,v in ipairs(queries) do
	v:Once("Created", function()
		amt = amt - 1
		if amt == 0 then
			ms.SetState("procedures", true)
			Inventory.MySQL.Log("All procedures ready!")
		end
	end)
end