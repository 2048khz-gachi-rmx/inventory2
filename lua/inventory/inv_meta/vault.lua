
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

vt:On("CanCrossInventoryTo", "Vault", function(self, ply, itm, inv2, slot)
	if hook.Run("Vault_CanMoveTo", self, itm, inv2, slot) == true then print("can move to vault via hook", itm) return true end

	if itm.AllowedVaultTransfer then
		return
	end

	return false
end)

vt:On("CanCrossInventoryFrom", "Vault", function(self, ply, itm, inv2, slot)
	if hook.Run("Vault_CanMoveFrom", self, ply, itm, inv2, slot) == true then return true end
	return false
end)

vt:On("CrossInventoryMovedTo", "Vault", function(self, itm, inv2, slot, fromSlot, ply)
	itm.AllowedVaultTransfer = false
end)

local allow = {
	Split = true,
	Move = true,
}

function vt:ActionCanInteract(ply, act)
	if self:GetOwner() ~= ply then return false end
	if allow[act] then return true end
end