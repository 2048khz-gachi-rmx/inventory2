
local bp = Inventory.GetClass("inv_meta", "backpack")
if not bp then error("Something went wrong while loading Vault: backpack is missing.") return end

local vt = Inventory.Inventories.Vault or bp:extend()
Inventory.Inventories.Vault = vt

vt.Name = "Vault"
vt:SetDescription("Safe storage for your items")

vt.SQLName = "ply_vault"
vt.NetworkID = 2
vt.MaxItems = 50
vt.IsVault = true


vt:Register()

--vt.ActionCanCrossInventoryFrom = CLIENT
--vt.ActionCanCrossInventoryTo = CLIENT

vt:On("ShouldShowF4", "DontShow", function()
	return false
end)

vt:On("CanMoveTo", "Vault", function(self, itm, inv2, slot)
	if inv2 == self then return true end
	if hook.Run("Vault_CanMoveTo", self, itm, inv2, slot) == true then return end

	if not inv2.IsBackpack then return false end
	if itm.AllowedVaultTransfer then
		return
	end

	return false
end)

vt:On("CanCrossInventoryFrom", "Vault", function(self, ply, itm, inv2, slot)
	if hook.Run("Vault_CanMoveFrom", self, ply, itm, inv2, slot) == true then return end
	return false
end)

vt:On("CrossInventoryMovedTo", "Vault", function(self, itm, inv2, slot)
	itm.AllowedVaultTransfer = false
end)