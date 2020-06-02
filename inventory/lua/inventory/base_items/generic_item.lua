--?

local Base = Inventory.BaseItemObjects.Generic or Emitter:callable()
Inventory.BaseItemObjects.Generic = Base


function Base:Initialize(name)
	assert(isstring(name), "New base items _MUST_ have a name assigned to them!")

	self.ItemName = name
	self:PullItemID()

	Inventory.BaseItems[self.ItemName] = self

	Inventory:Emit("BaseItemInit", self)
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

ChainAccessor(Base, "CamOffset", "CamOffset")
ChainAccessor(Base, "FOV", "FOV")
ChainAccessor(Base, "LookAng", "LookAng")


local its = muldim()
_ITS = its
Inventory:On("BaseItemInit", "EmitRegister", function(self, bi)
	local tick = engine.TickCount()
	its:Set(bi, tick, bi.ItemName)

	timer.Create("EmitRegistering" .. tick, 0, 1, function()
		for bname, bitem in pairs( its:Get(tick) ) do
			Inventory:Emit("BaseItemDefined", bitem, bname)
		end
		its[tick] = nil --clean up the garbage
	end)
end)