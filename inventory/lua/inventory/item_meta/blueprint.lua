--sasa

local gen = Inventory.GetClass("item_meta", "generic_item")
local bp = Inventory.ItemObjects.Blueprint or gen:Extend("Blueprint")

bp.IsBlueprint = true


function bp:Initialize(uid, ...)
	print("bp initialize:", ...)

end


bp:Register()