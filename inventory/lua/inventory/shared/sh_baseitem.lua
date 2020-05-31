
local conv = Inventory.IDConversion

function Inventory.Util.GetMeta(iid)
    return Inventory.ItemObjects.Generic
end

function Inventory.Util.ItemNameToID(name)
	return conv.ToID[name]
end

function Inventory.Util.ItemIDToName(id)
	return conv.ToName[id]
end

function Inventory.Util.IsInventory(obj)
	local mt = getmetatable(obj)
	return mt and mt.IsInventory
end

IsInventory = Inventory.Util.IsInventory


function BaseItemAccessor(it, varname, getname)
	it["Get" .. getname] = function(self)
		return self:GetBaseItem()[varname]
	end
end