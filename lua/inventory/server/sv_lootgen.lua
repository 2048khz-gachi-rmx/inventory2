Inventory.LootGen = Inventory.LootGen or {}
local LG = Inventory.LootGen

Inventory.LootGen.Pool = Inventory.LootGen.Pool or Emitter:extend()
local POOL = Inventory.LootGen.Pool

function POOL:Initialize(name)
	assert(isstring(name))
	self.Choices = {}
	self.ExtraData = {}
end

function POOL:_validate(name)
	if Inventory.Util.GetBase(name) == nil then
		errorNHf("no base for name %s", name)
		return false
	end

	return true
end

function POOL:_validateAll()
	for name, weight in pairs(self.Choices) do
		if not self:_validate(name) then
			self.Choices[name] = nil
			WeightedRand.InvalidateCache(self.Choices)
		end
	end
end

POOL.IsValid = TrueFunc

function POOL:Add(name, weight, extra)
	name = isstring(name) and name or Inventory.Util.ItemNameToID(name)

	if Inventory.MySQL.IDsReceived then
		if not self:_validate(name) then return end
	else
		Inventory:Once("ItemIDsReceived", self, function() self:_validateAll() end)
	end

	weight = tonumber(weight) or 1
	self.Choices[name] = weight
	self.ExtraData[name] = extra

	WeightedRand.InvalidateCache(self.Choices)
end

function POOL:Select()
	local pick = WeightedRand.Select(self.Choices)
	return pick, self.ExtraData[pick]
end

function POOL:SelectMultiple(n)
	local out = {}
	local outDat = {}
	n = tonumber(n)

	if n and n ~= 1 then
		WeightedRand.SelectNoRepeat(self.Choices, n, out)
	else
		out[1] = WeightedRand.Select(self.Choices)
	end

	for k,v in pairs(out) do
		outDat[k] = self.ExtraData[v]
	end

	return out, outDat
end


function LG.RandomAmount(a)
	a = a and a.Amount
	if not a then return 1 end

	if istable(a) then
		local min, max = a[1] or a.min, a[2] or a.max
		return math.random(min, max)
	else
		return tonumber(a)
	end
end

function LG.Generate(pool, amt)
	local ids, dat = pool:SelectMultiple(amt or 1)

	local out = {}

	for k,v in pairs(ids) do
		local itm = Inventory.NewItem(v)
		out[#out + 1] = itm

		local amt = LG.RandomAmount(dat[k])
		itm:SetAmount(amt)
	end

	return out
end