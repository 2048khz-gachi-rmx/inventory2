

local function regVault(inv, invname)
    if invname and invname ~= "Backpack" then return end --we rely on backpack

    local vt = Inventory.Inventories.Vault or Inventory.Inventories.Backpack:extend()
    Inventory.Inventories.Vault = vt

    vt.SQLName = "ply_vault"
    vt.NetworkID = 2
    vt.Name = "Vault"
    vt.MaxItems = 50

    vt:Register()
end


if Inventory.Inventories.Backpack then
    regVault()
else
    hook.Add("InventoryTypeRegistered", "VaultReg", function(inv, invname)
        regVault(inv, invname)
    end)
end