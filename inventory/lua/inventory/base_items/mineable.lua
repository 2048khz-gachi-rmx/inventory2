--?

local gen = Inventory.GetClass("base_items", "generic_item")
local Mineable = gen:Extend("Mineable", "Generic")

ChainAccessor(Mineable, "SmeltsTo", "SmeltsTo")

Mineable:Register()