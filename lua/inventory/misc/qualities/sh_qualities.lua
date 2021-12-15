--
Inventory.Quality = Inventory.Quality or Emitter:callable()
Inventory.Qualities = Inventory.Qualities or {}

Inventory.Qualities.ByType = Inventory.Qualities.ByType or muldim:new()
Inventory.Qualities.ByTier = Inventory.Qualities.ByTier or muldim:new()
Inventory.Qualities.ByName = Inventory.Qualities.ByName or {}

for i=1, 4 do
	Inventory.Qualities.ByTier:GetOrSet(i)
end

Inventory.Qualities.All = Inventory.Qualities.All or {}

local ql = Inventory.Quality
ql.IsQuality = true

ChainAccessor(ql, "Name", "Name")
ChainAccessor(ql, "ID", "ID")
ChainAccessor(ql, "Type", "Type")
ChainAccessor(ql, "MinStats", "MinStats")
ChainAccessor(ql, "MaxStats", "MaxStats")
ChainAccessor(ql, "Rarity", "Rarity")
ChainAccessor(ql, "Color", "Color")

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

function ql:SetName(name)
	if self:GetName() and Inventory.Qualities.ByName[self:GetName()] == self then
		Inventory.Qualities.ByName[self:GetName()] = nil
	end

	self.Name = name
	return self
end

function ql:_Remove()
	for k,v in ipairs(Inventory.Qualities.ByTier) do
		Inventory.Qualities.ByTier:RemoveSeqValue(self, k)
	end

	Inventory.Qualities.ByType:RemoveSeqValue(self, self:GetType())

	if self:GetName() and Inventory.Qualities.ByName[self:GetName()] == self then
		Inventory.Qualities.ByName[self:GetName()] = nil
	end
end

function ql:Initialize(name, id)
	assert(isnumber(id))
	assert(id < (bit.lshift(1, 16) - 1))

	local old = Inventory.Qualities.Get(id)
	if old and old:GetName() ~= name then
		errorNHf("ID collision: old [%s] -> new [%s]! ID: %s.", old:GetName(), name, id)
		local oldByName = Inventory.Qualities.Get(name)
		if oldByName then
			id = old:GetID()
			errorNHf("Recovered by using existing mod's ID (%s). This might not work someday, y'know?", id)
		end
	end

	if old then
		old:_Remove()
	end

	Inventory.Qualities.All[id] = self
	Inventory.Qualities.ByName[name] = self

	self:SetName(name)
		:SetID(id)
		:SetRarity(Inventory.Rarities.Default)

	self:SetColor(color_white:Copy())

	self.Stats = {}
	self.StatsGuarantee = {}

	self.ModsGuarantee = {}
	self.ModsBlacklist = {}
end

function ql:Alias(nm)
	Inventory.Qualities.ByName[nm] = self
end

function ql:AddStat(name, min, max, guarantee)
	local nm = Inventory.Enums.WeaponIDToStat(name)
	assertNHf(nm, "%s is not a stat!", name)
	min, max = math.Sort(min or 0, max or 0)

	if Inventory.Stats.IsGood(name) then
		local t = min
		min = max
		max = t
	end

	self.Stats[nm] = {min, max}

	if guarantee then
		self.StatsGuarantee[nm] = true
	end

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

function IsQuality(what)
	return istable(what) and what.IsQuality
end

function Inventory.Qualities.Get(nm)
	if IsQuality(nm) then return nm end
	if isstring(nm) then return Inventory.Qualities.ByName[nm] end
	return Inventory.Qualities.All[nm]
end

function Inventory.Qualities.GetErrored()
	return Inventory.Qualities.ByName["MissingQuality"]
end