

function ToUID(it)

	if isnumber(it) then return it
	elseif IsItem(it) then return it:GetUID()
	else errorf("ToUID: expected number or item as arg #1, got %s instead", type(it)) end

end

-- returns BaseItemMeta's name ( metas in base_items/*.lua )
function Inventory.Util.GetBaseMetaName(iid)
	local base = Inventory.Util.GetBase(iid)
	return base.BaseName
end

-- returns BaseItemMeta ( metas in base_items/*.lua )
function Inventory.Util.GetBaseMeta(iid)
	local name = Inventory.Util.GetBaseMetaName(iid)
	return name and Inventory.BaseItemObjects[name]
end


-- returns ItemMeta ( metas in item_meta/*.lua )
function Inventory.Util.GetMeta(iid)
	local base = Inventory.Util.GetBaseMeta(iid)
	if not base then return false end

	return Inventory.ItemObjects[base.ItemClass]
end

-- returns BaseItem (eg. Iron Ore or Copper Bar)
function Inventory.Util.GetBase(iid)
	return Inventory.BaseItems[iid]
end

function Inventory.Util.GetInventory(id)
	for k,v in pairs(Inventory.Inventories) do
		if v.NetworkID == id then
			return v
		end
	end
end

function Inventory.Util.GetItemCount(inv, id)
	local name = Inventory.Util.ItemIDToName(id)
	local amt = 0

	for k,v in pairs(inv:GetItems()) do
		if v.ItemName == name then
			amt = amt + (v:GetAmount() or 0)
		end
	end

	return amt
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