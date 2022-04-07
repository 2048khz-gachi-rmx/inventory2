--

local i = 1
local function make(nm)
	local q = Inventory.Quality:new(nm, i)
	i = i + 1

	q:SetTier(1, 2)
	q:SetType("Weapon")
	return q
end


make("MissingQuality")
	:SetColor(Color(160, 130, 55))
	:SetTier(-1)

--[==================================[
	T1
--]==================================]

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


--[==================================[
	T2
--]==================================]

make("Tolerable")
	:AddStat("HipSpread", -20, 20)
	:AddStat("Damage", 5, 15)
	:AddStat("MoveSpeed", 10, 20)
	:AddStat("Handling", 30, 60)
	:AddStat("MoveSpread", -25, 25)

	:SetMinStats(3)
	:SetMaxStats(4)

	:SetTier(2)
	:SetColor(Color(90, 205, 125))

make("Adverse")
	:AddStat("Damage", 10, 20, true)
	:AddStat("Spread", 15, 25, true)
	:AddStat("Recoil", 15, 30, true)
	:AddStat("RPM", -15, -25, true)

	:SetTier(2)
	:SetColor(Color(200, 105, 5))

make("Frisky")
	:AddStat("RPM", 10, 20, true)
	:AddStat("MoveSpeed", 5, 15, true)
	:AddStat("DrawTime", -10, -50, true)

		:AddStat("Damage", -15, -5)
		:AddStat("Spread", 10, 25)

	:SetMaxStats(4)
	:SetTier(2)
	:SetColor(Color(210, 215, 125))
	:Alias("Swift")

make("Steady")
	:AddStat("Recoil", -15, -25, true)
	:AddStat("Spread", 10, 25, true)
	:AddStat("Handling", -20, -40, true)

	:AddStat("HipSpread", -20, -35)
	:AddStat("MoveSpread", -10, -25)
	:AddStat("Damage", 10, 15)
		:AddStat("MoveSpeed", -5, -15)

	:SetTier(2)
	:SetColor(Color(230, 230, 30))

make("Dynamic")
	:AddStat("MoveSpeed", 15, 30, true)
	:AddStat("HipSpread", -20, -35, true)
	:AddStat("MoveSpread", -10, -25, true)
	:AddStat("Handling", 30, 60, true)

	:AddStat("Damage", -10, -20)

	:SetTier(2)
	:SetColor(Color(120, 205, 215))

--[==================================[
	T3
--]==================================]

make("Hurtful")
	:AddStat("Damage", 25, 40, true)
	:AddStat("Recoil", 20, 35, true)
	:AddStat("RPM", -10, -20, true)

	:AddStat("Spread", 5, 15)

	:SetTier(3)
	:SetColor(Color(220, 55, 55))

make("Erratic")
	:AddStat("RPM", 30, 50, true)
	:AddStat("Damage", 15, 25, true)
		:AddStat("Recoil", 30, 50, true)
		:AddStat("Spread", 40, 80, true)

	:AddStat("MoveSpeed", 15, 25)

	:SetTier(3)
	:SetColor(Color(220, 55, 200))

make("Reckless")
	:AddStat("Recoil", -10, -25, true)
	:AddStat("RPM", 20, 35, true)
	:AddStat("Spread", 15, 30, true)

	:SetTier(3)
	:SetColor(Color(220, 55, 200))
	:Alias("Rapid")

make("Blazing")
	:AddStat("Damage", 20, 30, true)
	:AddStat("Spread", 10, 25, true)
	:AddStat("Recoil", 10, 20, true)
	:AddStat("RPM", -10, -25, true)

	:SetTier(3)
	:SetColor(Color(200, 105, 5))
	:Alias("Fiery")

make("Lightweight")
	:AddStat("RPM", 20, 30, true)
	:AddStat("Handling", 40, 60, true)
	:AddStat("DrawTime", -45, -60, true)
		:AddStat("Spread", -15, -25, true)
		:AddStat("Damage", -10, -5, true)

	:AddStat("ReloadTime", 20, 50)
	:AddStat("MoveSpeed", 10, 30)
	:AddStat("Recoil", -20, -5)

	:SetTier(3)
	:SetColor(Color(140, 175, 210))
