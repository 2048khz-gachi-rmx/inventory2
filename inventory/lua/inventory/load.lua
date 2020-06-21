Inventory.AllClasses = Inventory.AllClasses or {}

function Inventory.GetClass(fold, name)
	name = name:PatternSafe()
	local obj

	for k,v in pairs(Inventory.AllClasses) do
		if v.FileName:match(name .. "[%.lua]*$") then obj = v break end
	end

	if obj then
		return obj
	else

		local included = 0

		FInc.Recursive("inventory/" .. fold:gsub("/$", "") .. "/*", _SH, nil, function(path)
			local fn = path:match(name .. "[%.lua]*$")
			if not fn then return false, false end --returning false stops the inclusion (twice for shared inclusion)

			print("included from Recursive", path, name)
			included = included + 1
			Inventory.Included[path] = true --so we don't re-include it in main inclusion script (the one in autorun)
		end)

		--after inclusion, try searching again and return if found
		for k,v in pairs(Inventory.AllClasses) do
			if v.FileName:match(name .. "[%.lua]*$") then return v end
		end

		--either didn't file the inclusion file or it failed to register its' object
		errorf("Failed to %s object %q. Search path: %s / %s", (included > 0 and "get registered") or "find the file for", name, fold, name)

	end
end

-- use addstack if this function is wrapped in an another file
-- for example, backpack's :Register() should add 1 to stack
-- otherwise every :Register() caller will think it's the backpack that registered it

function Inventory.RegisterClass(name, obj, tbl, addstack)
	local path = debug.getinfo(2 + (addstack or 0)).source
	local fn = path:match("[^/]+$")

	Inventory.AllClasses[fn] = obj

	tbl[name] = obj
	obj.FileName = fn
end