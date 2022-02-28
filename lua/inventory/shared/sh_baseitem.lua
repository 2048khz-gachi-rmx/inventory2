

function ToUID(it)

	if isnumber(it) then return it
	elseif IsItem(it) then return it:GetUID()
	else errorf("ToUID: expected number or item as arg #1, got %s instead", type(it)) end

end

-- returns BaseItemMeta's name ( metas in base_items/*.lua )
function Inventory.Util.GetBaseMetaName(iid)
	local base = Inventory.Util.GetBase(iid)
	return base and base.BaseName
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
	if not IsInventory(inv) and istable(inv) then
		local amt = 0
		for k,v in ipairs(inv) do
			amt = amt + Inventory.Util.GetItemCount(v, id)
		end

		return amt
	end

	id = Inventory.Util.ItemNameToID(id)
	local amt = 0

	for k,v in pairs(inv:GetItems()) do
		if v:GetItemID() == id then
			amt = amt + (v:GetAmount() or 0)
		end
	end

	return amt
end

function Inventory.Util.GetUsableInventories(ply)
	return {ply.Inventory.Backpack}
end

function Inventory.Util.ItemNameToID(name)
	return isnumber(name) and Inventory.IDConversion.ToName[name] and name
		or Inventory.IDConversion.ToID[name]
end

function Inventory.Util.ItemIDToName(id)
	return isstring(id) and Inventory.IDConversion.ToID[id] and id
		or Inventory.IDConversion.ToName[id]
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

function Inventory.Util.IsBaseItem(obj)
	local mt = getmetatable(obj)
	return mt and mt.IsBaseItem
end
IsBaseItem = Inventory.Util.IsBaseItem

function BaseItemAccessor(it, varname, getname)
	it["Get" .. getname] = function(self)
		local base = self:GetBaseItem()
		if not base then errorf("Item %s didn't have a base item!", it) return end

		return base[varname]
	end
end

function BaseItemAccessorFn(it, varname, getname)
	it["Get" .. getname] = function(self)
		local base = self:GetBaseItem()
		if not base then errorf("Item %s didn't have a base item!", it) return end

		return base["Get" .. varname] (base)
	end
end

local checks = {
	[FORCE_STRING] = isstring,
	[FORCE_NUMBER] = isnumber,
}

function DataAccessor(it, varname, getname, setcallback, force_type)
	local forceFn

	if isnumber(setcallback) then
		force_type = setcallback
		setcallback = nil
	end

	if force_type then
		if isnumber(force_type) then
			forceFn = checks[force_type] or errorf("unknown force enum: %s", force_type)
		elseif isfunction(force_type) then
			forceFn = force_type
		end
	end

	it["Get" .. getname] = function(self)
		return self.Data[varname]
	end

	it["Set" .. getname] = function(self, v)
		if forceFn and not forceFn(v) then
			errorf("bad #1 type to Set%s: %s (%s)", getname, v, type(v))
			return
		end

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