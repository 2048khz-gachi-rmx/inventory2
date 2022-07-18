local gen = Inventory.GetClass("item_meta", "generic_item")
local typ = Inventory.ItemObjects.Typed or gen:Extend("Typed")

DataAccessor(typ, "TypeID", "TypeID", nil, FORCE_NUMBER)

function typ:GetType()
	return self:GetTypes()[self:GetTypeID() or -1]
end

function typ:GetTypes()
	return self:GetBase().Types
end

typ:Register()