--
Inventory.Quality = Inventory.Quality or Emitter:callable()
Inventory.Qualities = Inventory.Qualities or {}

Inventory.Qualities.ByType = Inventory.Qualities.ByType or muldim:new()
Inventory.Qualities.ByTier = Inventory.Qualities.ByTier or muldim:new()

for i=1, 4 do
	Inventory.Qualities.ByTier:GetOrSet(i)
end

Inventory.Qualities.All = Inventory.Qualities.All or {}

local ql = Inventory.Quality
ChainAccessor(ql, "Name", "Name")
ChainAccessor(ql, "ID", "ID")
ChainAccessor(ql, "Type", "Type")

function ql:SetType(new)
	if self:GetType() ~= new and self:GetType() then
		Inventory.Qualities.ByType:RemoveSeqValue(self, self:GetType())
	end

	Inventory.Qualities.ByType:Insert(self, new)
	self.Type = new
	return self
end

function ql:SetTier(min, max)
	for k,v in ipairs(Inventory.Qualities.ByTier) do
		Inventory.Qualities.ByTier:RemoveSeqValue(self, k)
	end

	for t = min, max or min do
		Inventory.Qualities.ByTier:Insert(self, t)
	end
	return self
end

function ql:_Remove()
	for k,v in ipairs(Inventory.Qualities.ByTier) do
		Inventory.Qualities.ByTier:RemoveSeqValue(self, k)
	end

	Inventory.Qualities.ByType:RemoveSeqValue(self, self:GetType())
end

function ql:Initialize(name, id)
	assert(isnumber(id))

	local old = Inventory.Qualities.All[id]
	if old and old:GetName() ~= name then
		errorNHf("ID collision: old [%s] -> new [%s]! ID: %s.", old:GetName(), name, id)
	end

	if old then
		old:_Remove()
	end

	Inventory.Qualities.All[id] = self

	self:SetName(name)
		:SetID(id)

	self.Stats = {}

	self.ModsGuarantee = {}
	self.ModsBlacklist = {}
end

function ql:AddStat(name, min, max)
	local nm = Inventory.Enums.WeaponIDToStat(name)
	assertNHf(nm, "%s is not a stat!", name)
	min, max = math.Sort(min or 0, max or 0)
	self.Stats[nm] = {min, max}

	return self
end

function ql:GuaranteeMod(name, min, max)
	--assertNHf(Inventory.Modifiers.Get(name), "%s is not a modifier!", name)
	--self.ModsGuarantee[Inventory.Modifiers.ToName(name)] = {min, max}
	self.ModsGuarantee[name] = {min, max}

	return self
end

function ql:BlacklistMod(name)
	--assertNHf(Inventory.Modifiers.Get(name), "%s is not a modifier!", name)
	--self.ModsBlacklist[Inventory.Modifiers.ToName(name)] = true
	self.ModsGuarantee[name] = true

	return self
end