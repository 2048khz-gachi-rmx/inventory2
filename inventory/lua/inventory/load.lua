function Inventory.GetClass(name)
	name = name:PatternSafe()
	local obj

	for k,v in pairs(Inventory.BaseItemObjects) do
		if v.FileName:match(name .. "[%.lua]*$") then obj = v break end
	end

	if obj then
		return obj
	else

		FInc.Recursive("inventory/base_items/*", _SH, nil, function(path)
			local fn = path:match(name .. "[%.lua]*$")
			if not fn then return false end --returning false stops the inclusion
		end)

	end
end

function Inventory.RegisterBaseItem(name, obj)
	local path = debug.getinfo(2).source
	local fn = path:match("[^/]+$")

	Inventory.BaseItemObjects[name] = obj
	obj.FileName = fn
end