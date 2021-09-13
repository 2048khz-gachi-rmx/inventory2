Inventory.Enums.WeaponStats = {
	"Accuracy", "HipAccuracy", "MoveSpread",
	"Damage", "RPM", "Range", "ReloadSpeed", "MagSize",
	"Recoil", "Handling", "MoveSpeed", "DrawTime",
}

Inventory.Enums.WeaponStatsKeys = table.KeysToValues(Inventory.Enums.WeaponStats)


function Inventory.Enums.WeaponStatToID(what)
	if isnumber(what) then return what end
	return Inventory.Enums.WeaponStatsKeys[what]
end

function Inventory.Enums.WeaponIDToStat(what)
	if isstring(what) then return what end
	return Inventory.Enums.WeaponStats[what]
end