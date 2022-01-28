--
Inventory.Rarity = Inventory.Rarity or Emitter:callable()
Inventory.Rarities = Inventory.Rarities or {}

Inventory.Rarities.All = Inventory.Rarities.All or {}
Inventory.Rarities.ByName = Inventory.Rarities.ByName or {}
Inventory.Rarities.ByRarity = Inventory.Rarities.ByRarity or muldim:new()
Inventory.Rarities.ByID = Inventory.Rarities.All

local rar = Inventory.Rarity
rar.IsRarity = true

ChainAccessor(rar, "Name", "Name")
ChainAccessor(rar, "ID", "ID")
ChainAccessor(rar, "Color", "Color")
ChainAccessor(rar, "Rarity", "Rarity")

function rar:SetName(name)
	if self:GetName() and Inventory.Rarities.ByName[self:GetName()] == self then
		Inventory.Rarities.ByName[self:GetName()] = nil
	end

	self.Name = name
	Inventory.Rarities.ByName[name] = self
	return self
end

function rar:SetRarity(rty)
	if self:GetRarity() then
		Inventory.Rarities.ByRarity[self:GetRarity()]:RemoveSeqValue(self, self:GetRarity())
	end

	self.Rarity = rty
	Inventory.Rarities.ByRarity:Insert(self, rty)
	return self
end


function rar:Initialize(id)
	assert(isstring(id))

	Inventory.Rarities.All[id] = self
	self:SetName(id)
	self:SetColor(Colors.Red)
end

function IsRarity(what)
	return istable(what) and what.IsRarity
end

function Inventory.Rarities.Get(nm)
	if IsRarity(nm) then return nm end
	if isstring(nm) then
		return Inventory.Rarities.All[nm] or Inventory.Rarities.ByName[nm]
	end
end