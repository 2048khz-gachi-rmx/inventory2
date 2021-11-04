--?

local gen = Inventory.GetClass("base_items", "generic_item")
local Mineable = gen:ExtendItemClass("Mineable", "Generic")

Mineable.OreColor = color_white
Mineable.IsOre = true


ChainAccessor(Mineable, "SmeltsTo", "SmeltsTo")

ChainAccessor(Mineable, "SmeltTime", "SmeltTime")
Mineable.SmeltTime = 30

ChainAccessor(Mineable, "SpawnChance", "SpawnChance")
ChainAccessor(Mineable, "MinRarity", "MinRarity")
ChainAccessor(Mineable, "MaxRarity", "MaxRarity")
ChainAccessor(Mineable, "Weight", "Weight")
ChainAccessor(Mineable, "CanGenerate", "CanGenerate")

ChainAccessor(Mineable, "MineChanceMult", "MineChanceMult")
Mineable.MineChanceMult = 1

ChainAccessor(Mineable, "Cost", "Cost")
Mineable.Cost = 1

ChainAccessor(Mineable, "OreColor", "OreColor")
Mineable.OreColor = color_white:Copy()

Inventory.Mineables = Inventory.Mineables or {}

function Mineable:Initialize(name)
	Inventory.Mineables[name] = self --make sure more than 2 of the same item can't appear
end

function Mineable:SetSpawnAmount(min, max)
	if not min or not max then errorf("Missing one of the two arguments for Mineable:SetAmount! %s ; %s", min, max) end
	self.MinAmount, self.MaxAmount = min, max
end

Mineable:Register()