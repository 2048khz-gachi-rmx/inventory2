

function ToUID(it)
	return (isnumber(it) and it) or (IsItem(it) and it:GetUID()) or errorf("ToUID: expected number or item as arg #1, got %s instead", type(it))
end

function Inventory.Util.GetBaseMeta(iid)
	local base = Inventory.BaseItems[iid]
	if not base then print("no base") return false end

	local class = base.BaseName
	if not class then print("no base name") return false end

    return Inventory.BaseItemObjects[class]
end

function Inventory.Util.GetMeta(iid)
	local base = Inventory.Util.GetBaseMeta(iid)
	if not base then return false end

	return Inventory.ItemObjects[base.ItemClass]
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
		if not base then errorf("Item %s didn't have a base item!", it) return end

		return base[varname]
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