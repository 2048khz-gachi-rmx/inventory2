--?
E = (E or 0) + 1
print("AEIOU", E, debug.traceback())
--Inventory.ExtendBaseItem("Generic")
local gen = Inventory.GetClass("base_items", "generic_item")
local Mineable = gen:Extend("Mineable")

ChainAccessor(Mineable, "SmeltsTo", "SmeltsTo")