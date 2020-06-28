--?
print("generic included")
local Base = Inventory.BaseItemObjects.Generic or Emitter:callable()
Base.BaseName = "Generic"
Base.ItemClass = "Generic"
Base.ShouldSpin = true
Base.Extensions = Base.Extensions or {}

Base.NetworkedVars = {}

--Extend = a new class is being extended from base (e.g. 'Equipment' from 'Generic')
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

	--if name ~= self.BaseName then
		self.Extensions[name] = new
	--end
end

--Initialize = a BaseItem instance is being constructed (e.g. 'Watermelon' from 'Generic')
function Base:Initialize(name)
	assert(isstring(name), "New base items _MUST_ have a name assigned to them!")

	self.NetworkedVars = {}

	local base = self.__instance
	for k,v in ipairs(base.NetworkedVars) do
		self.NetworkedVars[k] = v
	end

	self.DefaultData = {}

	self.Deletable = true

	self.ItemName = name

	self.BaseName = self.BaseName -- stop __indexes and make it show up when rawprinting the item
	self.ItemClass = self.ItemClass

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
				print("ItemName is", self.ItemName, toid[self.ItemName])
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

function Base:NetworkVar(net_typ, what, ...)
	local typ = types[net_typ]
	local given = select('#', ...)

	if isnumber(typ) and given ~= typ - 1 then errorf("Mismatched amount of args provided (%d) vs. args needed (%d): %s", given, typ, ...) return end
	if not isstring(what) and not isfunction(what) then errorf("NetworkVar accepts either a string (key in its' .Data table) or a function which determines how to network! Got %s instead", type(what)) return end
	if self.NetworkedVars[what] then return end

	self.NetworkedVars[#self.NetworkedVars + 1] = {type = net_typ, what = what, args = {...}}
	self.NetworkedVars[what] = net_typ
	return self
end

ChainAccessor(Base, "Name", "Name")
ChainAccessor(Base, "Model", "Model")

ChainAccessor(Base, "CamPos", "CamPos")
ChainAccessor(Base, "FOV", "FOV")
ChainAccessor(Base, "LookAng", "LookAng")
ChainAccessor(Base, "ShouldSpin", "ShouldSpin")

function Base:SetCountable(b)

	if not self.Countable and b == true then
		table.insert(self.NetworkedVars, 1, {
			type = "UInt",
			what = "Amount",
			args = {self:GetMaxStack() and bit.GetLen(self:GetMaxStack()) or 32}
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

Base:On("CreatedInstance", "Stackable", function(self, item)

end)

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
				v.args[1] = bit.GetLen(st)
			end
		end
	end

	self.MaxStack = st
	return self
end

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
			if not v.FilePath or not v.FileName then errorf("What the fuck hello", k) return end

			Inventory.IncludeClass(fp, fn)
		end
	end

end

Base:Register(-1)
--Inventory.RegisterClass("Generic", Base, Inventory.BaseItemObjects)






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


--todo: stick this somewhere else
hook.Add("InventoryGetOptions", "DeletableOption", function(it, mn)
	if not it:GetDeletable() then return end

	local opt = mn:AddOption("Delete Item")
	opt.HovMult = 1.15
	opt.Color = Color(150, 30, 30)
	opt.DeleteFrac = 0

	local delCol = Color(230, 60, 60)
	function opt:Think()
		if self:IsDown() then
			self:To("DeleteFrac", 1, 1, 0, 0.25)
		else
			self:To("DeleteFrac", 0, 0.5, 0, 0.3)
		end

		if self.DeleteFrac == 1 and not self.Sent then
			Inventory.Networking.DeleteItem(it)
			self.Sent = true
			mn:PopOut()
			mn:SetMouseInputEnabled(false)
		end
	end

	function opt:PreTextPaint(w, h)
		surface.SetDrawColor(delCol)
		surface.DrawRect(0, 0, w * self.DeleteFrac, h)
	end
end)