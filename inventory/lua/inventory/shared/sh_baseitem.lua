

function ToUID(it)
	return (isnumber(it) and it) or (IsItem(it) and it:GetUID()) or errorf("ToUID: expected number or item as arg #1, got %s instead", type(it))
end

function Inventory.Util.GetMeta(iid)
    return Inventory.ItemObjects.Generic
end

function Inventory.Util.GetBase(id)
	return Inventory.BaseItems[id]
end

function Inventory.Util.ItemNameToID(name)
	return isnumber(name) and name or Inventory.IDConversion.ToID[name]
end

function Inventory.Util.ItemIDToName(id)
	return isstring(id) and id or Inventory.IDConversion.ToName[id]
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
		if not base then errorf("Item %s didn't have a base item!", it) end

		return base and base[varname]
	end
end

function DataAccessor(it, varname, getname, setcallback)
	it["Get" .. getname] = function(self)
		return self.Data[varname]
	end

	it["Set" .. getname] = function(self, v)
		self.Data[varname] = v
		local inv = self:GetInventory()

		if inv then
			inv:AddChange(self, INV_ITEM_DATACHANGED)
		end

		if setcallback then
			setcallback(self, v)
		end

		if SERVER then return Inventory.MySQL.ItemSetData(self, {[varname] = v}) end
	end
end