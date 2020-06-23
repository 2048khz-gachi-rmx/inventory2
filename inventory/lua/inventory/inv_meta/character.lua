
local bp = Inventory.GetClass("inv_meta", "backpack")
if not bp then error("Something went wrong while loading Character inventory: backpack is missing.") return end

local char = Inventory.Inventories.Character or bp:extend()

char.SQLName = "ply_charinv"
char.NetworkID = 3
char.Name = "Character"
char.MaxItems = 50

char:On("CanOpen", function()
	return false
end)

char:Register()