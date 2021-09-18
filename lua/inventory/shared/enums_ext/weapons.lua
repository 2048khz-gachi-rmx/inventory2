Inventory.Enums.WeaponStats = {
	"Spread", "HipSpread", "MoveSpread",
	"Damage", "RPM", "Range", "ReloadTime", "MagSize",
	"Recoil", "Handling", "MoveSpeed", "DrawTime",
}

Inventory.Enums.WeaponStatsKeys = table.KeysToValues(Inventory.Enums.WeaponStats)
Inventory.Enums.WeaponStatsSz = bit.GetLen(#Inventory.Enums.WeaponStats)

function Inventory.Enums.WeaponStatToID(what)
	if isnumber(what) and Inventory.Enums.WeaponStats[what] then return what end
	return Inventory.Enums.WeaponStatsKeys[what]
end

function Inventory.Enums.WeaponIDToStat(what)
	if isstring(what) and Inventory.Enums.WeaponStatsKeys[what] then return what end
	return Inventory.Enums.WeaponStats[what]
end

Inventory.Stats = {}
Inventory.Stats.BitAccuracy = 10

function Inventory.Stats.Encode(stat, fr)
	return Inventory.Enums.WeaponStatToID(stat),
		math.Round(fr * bit.lshift(1, Inventory.Stats.BitAccuracy))
end

function Inventory.Stats.Decode(id, num)
	return Inventory.Enums.WeaponIDToStat(id),
		num / bit.lshift(1, Inventory.Stats.BitAccuracy)
end

function Inventory.Stats.Write(stat, fr, ns)
	local id, nm = Inventory.Stats.Encode(stat, fr)

	if ns then
		ns:WriteUInt(id, Inventory.Enums.WeaponStatsSz)
		ns:WriteUInt(nm, Inventory.Stats.BitAccuracy)
	else
		net.WriteUInt(id, Inventory.Enums.WeaponStatsSz)
		net.WriteUInt(nm, Inventory.Stats.BitAccuracy)
	end
end

function Inventory.Stats.Read()
	local nid = net.ReadUInt(Inventory.Enums.WeaponStatsSz)
	local num = net.ReadUInt(Inventory.Stats.BitAccuracy)

	local name, fr = Inventory.Stats.Decode(nid, num)

	return name, fr
end

local reverse = table.KeysToValues({
	"Handling",
})

local goodNeg = table.KeysToValues({
	"DrawTime",
	"Recoil",
	"ReloadTime",
	"MoveSpread",
	"HipSpread",
	"Spread"
})

function Inventory.Stats.NegPos(stat, amt)

	local good = amt > 0

	if goodNeg[stat] then
		good = amt < 0
	end

	if reverse[stat] then
		amt = -amt
	end

	local col = good and Colors.Money or Colors.Reddish

	return ("%s%s%%"):format(
		amt > 0 and "+" or "",
		("%.1f"):format(amt):gsub("%.", ","):gsub(",0+$", "")
	), col, good
end

function Inventory.Stats.ToName(stat)
	return Language("Inv_Stat" .. stat)
end