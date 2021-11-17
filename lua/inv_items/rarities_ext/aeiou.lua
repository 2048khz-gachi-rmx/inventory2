-- eeee

local rar = Inventory.Rarity("common")
	:SetName("Common")
	:SetColor(Color(200, 200, 200))
	:SetRarity(1)

Inventory.Rarities.Default = rar


Inventory.Rarity("uncommon")
	:SetName("Uncommon")
	:SetColor(Color(70, 250, 70))
	:SetRarity(2)

Inventory.Rarity("legendary")
	:SetName("Legendary")
	:SetColor(Color(255, 80, 20))
	:SetRarity(6)