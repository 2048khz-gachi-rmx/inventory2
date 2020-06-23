
local bp = Inventory.GetClass("inv_meta", "backpack")
if not bp then error("Something went wrong while loading Character inventory: backpack is missing.") return end

local char = Inventory.Inventories.Character or bp:extend()

char.SQLName = "ply_charinv"
char.NetworkID = 4
char.Name = "Character"
char.MaxItems = 50
char.UseSlots = false

char.SQLColumns = {
	{
		name = "slotid",
		type = "VARCHAR(64)",
		attr = "NOT NULL",
		unique = {"puid", "uid"}
	}
}

char:On("CanOpen", function()
	return false
end)


function char:Equip(it)

end

char:Register()