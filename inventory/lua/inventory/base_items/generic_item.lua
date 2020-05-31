--?

local Base = Inventory.BaseItemObjects.Generic or Emitter:callable()
Inventory.BaseItemObjects.Generic = Base


function Base:Initialize(name)
	assert(isstring(name), "New base items _MUST_ have a name assigned to them!")

	self.ItemName = name
	self:PullItemID()

	Inventory.BaseItems[self.ItemName] = self
end

function Base:SetID(id)
	if not isnumber(id) then errorf('Base:SetID(): expected "number", got %q instead (%s)', type(id), id) end

	self.ItemID = id
	Inventory.BaseItems[id] = self

	self:Emit("AssignedID")
end

function Base:PullItemID()

	if SERVER then 
		Inventory.MySQL.AssignItemID(self.ItemName, self.SetID, self) 
	else
		local exists_id = Inventory.IDConversion.ToID[self.ItemName]

		if not exists_id then
			hook.Once("InventoryIDReceived", "BaseItemAssign" .. self.ItemName, function(toname, toid)
				self:SetID(toid[self.ItemName])
			end)
		else
			self:SetID(exists_id)
		end
	end

end

ChainAccessor(Base, "Name", "Name")
ChainAccessor(Base, "Model", "Model")