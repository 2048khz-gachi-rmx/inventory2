--

local i = 1
local function make(nm)
	local q = Inventory.Quality:new(nm, i)
	i = i + 1

	q:SetTier(1, 2)
	q:SetType("Weapon")
	return q
end


make("Fiery")
	:AddStat("Damage", 20, 35, true)
	:AddStat("Spread", 10, 25, true)
	:AddStat("RPM", -10, -25, true)

	:GuaranteeMod("Blazing")
	:SetTier(2, 4)
	:SetColor(Color(200, 105, 5))

make("Swift")
	:AddStat("RPM", 15, 40, true)
	:AddStat("MoveSpeed", 5, 15, true)
	:AddStat("DrawTime", -10, -50, true)

	:AddStat("Damage", -15, -5, true)
	:AddStat("Spread", 10, 25)
	:SetTier(2)
	:SetColor(Color(120, 205, 215))

make("Lightweight")
	:AddStat("Spread", -15, -25, true)
	:AddStat("Handling", 20, 60, true)
	:AddStat("MoveSpeed", 10, 30)
	:AddStat("DrawTime", 25, 60, true)
	:AddStat("ReloadTime", 20, 50)

	:AddStat("Damage", -5, 5, true)
	:AddStat("Recoil", -20, -5)
	:SetTier(3, 4)
	:SetColor(Color(140, 175, 210))

-- overall sucks but its possible it'll have a damage up
make("Salvaged")
	:AddStat("Spread", -5, 10, true)
	:AddStat("ReloadTime", 10, 40, true)
	:AddStat("Range", -30, -15, true)
	:AddStat("Recoil", 10, 30, true)

	:AddStat("Damage", 15, 25)
	:AddStat("Handling", -20, -10)
	:AddStat("MoveSpeed", -10, -2)
	:AddStat("DrawTime", -20, -10)

	:SetColor(Color(160, 130, 55))

	:SetTier(1)

-- wildly random stats
make("Scavenged")
	:AddStat("Spread", -25, 50)
	:AddStat("Handling", -35, 50)
	:AddStat("MoveSpeed", -20, 40)
	:AddStat("ReloadTime", -40, 60)
	:AddStat("MagSize", -20, 40)

	:AddStat("Damage", -10, 10)
	:AddStat("Range", -20, 35)
	:AddStat("Recoil", -30, 50)
	:SetMinStats(2)
	:SetMaxStats(5)
	:SetTier(1)

	:SetColor(Color(165, 115, 55))