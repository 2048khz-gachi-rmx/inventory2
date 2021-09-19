
local bp = Inventory.GetClass("inv_meta", "backpack")
if not bp then error("Something went wrong while loading Vault: backpack is missing.") return end

local vt = Inventory.Inventories.Vault or bp:extend()
Inventory.Inventories.Vault = vt

vt.SQLName = "ply_vault"
vt.NetworkID = 2
vt.Name = "Vault"
vt.MaxItems = 50

vt:Register()

vt.ActionCanCrossInventoryFrom = CLIENT
vt.ActionCanCrossInventoryTo = CLIENT