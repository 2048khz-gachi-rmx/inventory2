Inventory.Enum = {}
Inventory.Enums = Inventory.Enum

FInc.FromHere("enums_ext/*", _SH)

local PLAYER = FindMetaTable("Player")

function Inventory.GetEquippableInventory(ply)
	return ply.Inventory.Character
end

PLAYER.GetEquipment = Inventory.GetEquippableInventory

function Inventory.GetTemporaryInventory(ply)
	return ply.Inventory.Backpack
end

PLAYER.GetBackpack = Inventory.GetTemporaryInventory

function Inventory.GetVault(ply)
	return ply.Inventory.Vault
end

PLAYER.GetVault = Inventory.GetVault