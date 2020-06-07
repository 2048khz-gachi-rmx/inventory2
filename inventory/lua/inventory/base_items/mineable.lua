--?

--Inventory.ExtendBaseItem("Generic")
local gen = Inventory.GetClass("generic_item")
local Mineable = gen:Extend()

ChainAccessor(Mineable, "SmeltsTo", "SmeltsTo")