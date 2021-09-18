--
local wep = Inventory.ItemObjects.Weapon

hook.Add("ArcCW_ShouldShowAtt", "InventoryRestrict", function(att)
	if Inventory.ArcCW_InventoryAttachments[att] then return false end
end)