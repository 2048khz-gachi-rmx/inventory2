
local Base = Inventory.BaseItemObjects.Generic or Emitter:callable()
Base.BaseName = "Generic"
Base.ItemClass = "Generic"
Base.ShouldSpin = true
Base.Extensions = Base.Extensions or {}

Base.IsBaseItem = true

Base.NetworkedVars = {}

-- Extend = a new class is being extended from base (e.g. 'Equipment' from 'Generic')
-- `name` is just the name of the new base class

-- `class` is what item meta instances of this base class should use (the ones players hold)

function Base:OnExtend(new, name, class)
	if not isstring(name) then error("Base item extensiosns _MUST_ have a name assigned to them!") return end

	local old = Inventory.BaseItemObjects[name]
	if old then
		-- existed before, so carry over the "Extensions" table
		new.Extensions = old.Extensions
	else
		new.Extensions = {} --didn't exist before, reset the extensions table so we don't inherit it
	end
	new.FileName, new.FilePath = false, false
	new.BaseName = name
	new.ItemClass = class
	new.NetworkedVars = {}

	for k,v in pairs(self.NetworkedVars) do
		new.NetworkedVars[k] = v
	end

	--if name ~= self.BaseName then
		self.Extensions[name] = new
		Inventory.BaseItemObjects[name] = self
	--end
end

function Base:ExtendItemClass(name, class, forceNew)
	if forceNew or not Inventory.BaseItemObjects[name] then
		return self:callable(name, class)
	else
		return Inventory.BaseItemObjects[name]
	end
end

--Initialize = a BaseItem instance is being constructed (e.g. 'Watermelon' from 'Generic')
function Base:Initialize(name)
	assert(isstring(name), "New base items _MUST_ have a name assigned to them!")

	self.NetworkedVars = {}

	local base = self.__instance
	for k,v in ipairs(base.NetworkedVars) do
		self.NetworkedVars[k] = v
	end

	--self.NetworkedVars = self.__instance.NetworkedVars

	self.DefaultData = {}

	self.Deletable = true

	self.ItemName = name --ID as a string
	self.Name = name --nice name, can be overridden

	-- copy to the instance
	self.BaseName = self.BaseName
	self.ItemClass = self.ItemClass

	self:PullItemID()
	self:SetRarity(Inventory.Rarities.Default)

	Inventory.BaseItems[self.ItemName] = self

	Inventory:Emit("BaseItemInit", self)
end

function Base:OverrideItemClass(new)
	self.ItemClass = new
	return self
end

function Base:SetRarity(rar)
	if IsRarity(rar) then self.Rarity = rar return self end
	local r = Inventory.Rarities.Get(rar)
	if not r then
		errorf("unknown rarity: %s", r)
	end

	self.Rarity = r

	return self
end

function Base:SetID(id)
	if not isnumber(id) then errorf('Base:SetID(): expected "number", got %q instead (%s)', type(id), id) end

	self.ItemID = id
	Inventory.BaseItems[id] = self

	self:Emit("AssignedID", id)
	self:_MakeReady()
end

function Base:_MakeReady()

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

function Base:AddDefaultData(name, var)
	self.DefaultData[name] = var
end

-- `what` may be a function which **must return a netstack**!!!
-- if it's a function then the second argument will be whether the var is being read or written
-- `true` if written, `false` if read

function Base:NetworkVar(net_typ, what, id, ...)
	local typ = types[net_typ]
	local given = select('#', ...)
	local args = {...}

	if not isfunction(what) and id then
		table.insert(args, 1, id)
		given = given + 1
		id = nil
	end

	if isnumber(typ) and given ~= typ - 1 then errorf("Mismatched amount of args provided (%d) vs. args needed (%d): %s", given, typ - 1, table.concat(args)) return end
	if not isstring(what) and not isfunction(what) then errorf("NetworkVar accepts either a string (key in its' .Data table) or a function which determines how to network! Got %s instead", type(what)) return end
	if isfunction(what) and not id then errorf("NetworkVar needs an ID as the 3rd argument if you provide a function as the second arg!") return end

	local key = #self.NetworkedVars + 1
	if istable(self.NetworkedVars[id or what]) then key = self.NetworkedVars[id or what].id end

	local t = {type = net_typ, what = what, args = args, id = key}

	self.NetworkedVars[key] = t
	self.NetworkedVars[id or what] = t
	return self
end

ChainAccessor(Base, "Name", "Name")

function Base:GetID()
	return self.ItemID
end
Base.GetItemID = Base.GetID

ChainAccessor(Base, "ItemName", "ItemName")
ChainAccessor(Base, "Model", "Model")
ChainAccessor(Base, "ModelColor", "ModelColor")
ChainAccessor(Base, "Color", "Color")
ChainAccessor(Base, "Rarity", "Rarity", true)

Base.BaseTransferCost = 10000
ChainAccessor(Base, "BaseTransferCost", "BaseTransferCost")

ChainAccessor(Base, "CamPos", "CamPos")
ChainAccessor(Base, "FOV", "FOV")
ChainAccessor(Base, "LookAng", "LookAng")
ChainAccessor(Base, "ShouldSpin", "ShouldSpin")

function Base:SetCountable(b)

	if not self.Countable and b == true then
		if self.NetworkedVars[1] and self.NetworkedVars[1].what == "Amount" then return self end --already countable or somethin'?

		local mx = self:GetMaxPossibleStack() or self:GetMaxStack()
		local len = mx and math.max(8, bit.GetLen(mx))

		table.insert(self.NetworkedVars, 1, {
			type = "UInt",
			what = "Amount",
			args = {len or 32}
		})

		self:AddDefaultData("Amount", 1)

	elseif self.Countable and b == false and self.NetworkedVars[1] and self.NetworkedVars[1].what == "Amount" then

		table.remove(self.NetworkedVars, 1)
		self.DefaultData["Amount"] = nil
	end

	self.Countable = b
	return self
end

function Base:IsCountable()
	return self.Countable
end

Base.GetCountable = Base.IsCountable

ChainAccessor(Base, "MaxStack", "MaxStack")

function Base:SetUsable(b, func)
	self.Usable = b
	self.UseFunc = func
end

function Base:GetUsable()
	return self.Usable, self.UseFunc
end

function Base:SetMaxStack(st)
	if self.Countable then
		for k,v in ipairs(self.NetworkedVars) do
			if v.what == "Amount" then
				v.args[1] = math.max(8, bit.GetLen(st))
			end
		end
	end

	self.MaxStack = st
	return self
end

ChainAccessor(Base, "MaxPossibleStack", "MaxPossibleStack") -- for NW

function Base:On(...) --convert :On() into a chainable function
	Emitter.On(self, ...)
	return self
end

function Base:Register(addstack)
	local old = Inventory.BaseItemObjects[self.BaseName]

	Inventory.RegisterClass(self.BaseName, self, Inventory.BaseItemObjects, (addstack or 0) + 1)

	if old then
		-- we existed before registering, that means the script
		-- that registered this file got updated, so also update everyone
		-- that depended on this class

		for k,v in pairs(self.Extensions) do
			local fp, fn = rawget(v, "FilePath"), rawget(v, "FileName") --don't inherit those to avoid infinite loops

			if k == self.BaseName then errorf("Infinite inclusion loop averted: %q is equal to %q", k, self.BaseName) return end
			if not fp or not fn then --[[errorf("What the fuck hello", k)]] return end

			Inventory.IncludeClass(fp, fn)
		end
	end

end

Base:Register(-1)
--Inventory.RegisterClass("Generic", Base, Inventory.BaseItemObjects)



-- hey past me, wtf is this?

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

if CLIENT then
	include("generic_item_cl_ext.lua")
end