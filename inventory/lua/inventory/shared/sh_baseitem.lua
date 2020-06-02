


function Inventory.Util.GetMeta(iid)
    return Inventory.ItemObjects.Generic
end

function Inventory.Util.ItemNameToID(name)
	return Inventory.IDConversion.ToID[name]
end

function Inventory.Util.ItemIDToName(id)
	return Inventory.IDConversion.ToName[id]
end

function Inventory.Util.IsInventory(obj)
	local mt = getmetatable(obj)
	return mt and mt.IsInventory
end

IsInventory = Inventory.Util.IsInventory

function Inventory.Util.IsItem(obj)
	local mt = getmetatable(obj)
	return mt and mt.IsItem
end

IsItem = Inventory.Util.IsItem


function BaseItemAccessor(it, varname, getname)
	it["Get" .. getname] = function(self)
		local base = self:GetBaseItem()
		if not base then errorf("Item %q didn't have a base item!", it:GetName()) end
		return base and base[varname]
	end
end