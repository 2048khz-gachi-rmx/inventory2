--?

local Base = Inventory.BaseItemObjects.Generic or Emitter:callable()
Inventory.BaseItemObjects.Generic = Base


function Base:Initialize(name)
	assert(isstring(name), "New base items _MUST_ have a name assigned to them!")

	self.NetworkedVars = {}

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

local types = {
	Int = 2,
	Float = 1,
	Bool = 1,
	Angle = 1,
	Bit = 1,
	Normal = 1,
	UInt = 2,
	Color = 1,
	Double = 1,
	Data = 2,
	Entity = 1,
	String = 1,

	NetStack = true,
	Any = true,
}

function Base:NetworkVar(net_typ, what, ...)
	local typ = types[net_typ]
	local given = select('#', ...)

	if isnumber(typ) and given ~= typ - 1 then errorf("Mismatched amount of args provided (%d) vs. args needed (%d): %s", given, typ, ...) return end
	if not isstring(what) and not isfunction(what) then errorf("NetworkVar accepts either a string (key in its' .Data table) or a function which determines how to network! Got %s instead", type(what)) return end

	self.NetworkedVars[#self.NetworkedVars + 1] = {type = net_typ, what = what, args = {...}}
	return self
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