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
	:AddStat("Damage", 5, 30)
	:AddStat("Accuracy", -30, -5)

	:GuaranteeMod("Blazing")

make("Swift")
	:AddStat("RPM", 15, 40)
	:AddStat("MoveSpeed", 5, 15)
	:AddStat("DrawTime", 10, 40)

	:AddStat("Damage", -5, 5)
	:AddStat("Accuracy", -15, 0)


make("Lightweight")
	:AddStat("Accuracy", 5, 15)
	:AddStat("Handling", 20, 60)
	:AddStat("MoveSpeed", 10, 30)
	:AddStat("DrawTime", 25, 60)
	:AddStat("ReloadTime", 20, 50)

	:AddStat("Damage", -5, 5)
	:AddStat("Recoil", -20, -5)
	:SetTier(3)