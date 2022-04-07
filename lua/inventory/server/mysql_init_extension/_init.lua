-- DB is not guaranteed to be initialized here;
-- only define helpers in here

-- Files in subfolders will only be included after DB initializes

local ms = Inventory.MySQL
local db = ms.DB


local format = [[CREATE %s `%s`(
	%s
)%s
BEGIN
-- <Body>
%s
-- </Body>
END;]]


local function tblToArgs(args)
	if not isstring(args) and not IsArgList(args) then errorf("Unrecognized type: %q.", type(args)) return end

	return tostring(args)
end

local function isError(s)
	if s:lower():match("procedure %S+ already exists") then return false end
	if s:lower():match("function %S+ already exists") then return false end
	return true
end

function ms.CreateProcedure(name, args, body)
	local argList = tblToArgs(args)

	local qr = format:format("PROCEDURE", name, argList, "", body)
	local qry = db:query(qr)

	local q = MySQLEmitter(qry, true)

	q:Then(function(...)
		Inventory.Log("Created procedure `" .. name .. "` successfully!", ...)
		q:Emit("Created")
	end, function(self, qry, err)
		if isError(err) then
			Inventory.LogError("SQL Procedure creation error: %s", err)
			return
		end

		q:Emit("Created")
	end)

	return q
end

function ms.CreateFunction(name, args, rettype, body)
	local argList = tblToArgs(args)

	local qr = format:format("FUNCTION", name, argList, " " .. rettype, body)
	local qry = db:query(qr)

	local q = MySQLEmitter(qry, true)

	q:Then(function(...)
		Inventory.Log("Created procedure `" .. name .. "` successfully!", ...)
		q:Emit("Created")

	end, function(self, qry, err)
		if isError(err) then
			Inventory.LogError("SQL Function creation error: %s", err)
			return
		end

		q:Emit("Created")
	end)

	return q
end

ms._InitQueue = ms._InitQueue or {}
ms._States = ms._States or {}

-- waits for the query to complete and then sets every string passed as ... to +1
-- great for creating dependencies where, for example,
-- player inventory tables would require "items" and "functions" states

function ms.StateSetQuery(q, ...)
	if not IsMySQLEmitter(q) then
		errorf("expected MySQLEmitter, got %q instead", type(q))
		return
	end

	ms._InitQueue[#ms._InitQueue + 1] = q

	local states = {...}

	for k,v in ipairs(states) do
		ms._States[v] = false
	end

	q:Once("Success", function()
		for k,v in ipairs(states) do
			ms.SetState(v, true)
		end

		Inventory.MySQL:Emit("StatesChanged", unpack(states))
	end)

	return q
end

function ms.SetState(state, b)
	ms._States[state] = b
	Inventory.MySQL:Emit("StatesChanged", state)

	for k,v in pairs(ms._States) do
		if v == false then return end
	end

	-- all registered states were set
	hook.Run("InventoryMySQLInitialized") -- procedures & tables & all that good stuff was initialized
end

function ms.RegisterState(state)
	if not ms._States[state] then
		ms._States[state] = false
	end
end

function ms.WaitStates(cb, ...)
	local states = {...}

	local ready = true

	for k,v in ipairs(states) do
		if not ms._States[v] then ready = false break end
	end

	if ready then
		-- if all the states are set, just call the thing
		cb()
	else
		local num; num = Inventory.MySQL:On("StatesChanged", function()
			for k,v in ipairs(states) do
				if not ms._States[v] then return end
			end

			xpcall(cb, GenerateErrorer("StateChangeError"))
			Inventory.MySQL:RemoveListener("StatesChanged", num)
		end)
	end
end


-- include DB initializers only if DB is connected
local inc = function()
	FInc.FromHere("*", _SV, function(path)
		if path:match("_init%.lua") then return false end
	end)
end

if not ms._Connected then
	hook.Once("InventoryMySQLConnected", "InitializeDB", inc)
else
	inc()
end
