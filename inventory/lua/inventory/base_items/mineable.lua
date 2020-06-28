--?

local gen = Inventory.GetClass("base_items", "generic_item")
local Mineable = gen:callable("Mineable", "Generic")

ChainAccessor(Mineable, "SmeltsTo", "SmeltsTo")
ChainAccessor(Mineable, "SpawnChance", "SpawnChance")
ChainAccessor(Mineable, "MinRarity", "MinRarity")
ChainAccessor(Mineable, "MaxRarity", "MaxRarity")

Inventory.Mineables = Inventory.Mineables or {}

function Mineable:Initialize(name)
	Inventory.Mineables[name] = true --make sure more than 2 of the same item can't appear
end

function Mineable:SetSpawnAmount(min, max)
	if not min or not max then errorf("Missing one of the two arguments for Mineable:SetAmount! %s ; %s", min, max) end
	self.MinAmount, self.MaxAmount = min, max
end

Mineable:Register()