Inventory.Enum = {}
Inventory.Enums = Inventory.Enum

FInc.FromHere("enums_ext/*", _SH)


function Inventory.GetEquippableInventory(ply)
	return ply.Inventory.Character
end

function Inventory.GetTemporaryInventory(ply)
	return ply.Inventory.Backpack
end