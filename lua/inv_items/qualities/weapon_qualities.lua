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
	:AddStat("Damage", 20, 35)

	:AddStat("Spread", 10, 25)
	:AddStat("RPM", -10, -25)

	:GuaranteeMod("Blazing")


make("Swift")
	:AddStat("RPM", 15, 40)
	:AddStat("MoveSpeed", 5, 15)
	:AddStat("DrawTime", -10, -50)

	:AddStat("Damage", -15, -5)
	:AddStat("Spread", 10, 25)


make("Lightweight")
	:AddStat("Spread", -15, -25)
	:AddStat("Handling", 20, 60)
	:AddStat("MoveSpeed", 10, 30)
	:AddStat("DrawTime", 25, 60)
	:AddStat("ReloadTime", 20, 50)

	:AddStat("Damage", -5, 5)
	:AddStat("Recoil", -20, -5)
	:SetTier(3)