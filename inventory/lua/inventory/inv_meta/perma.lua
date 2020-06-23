
local bp = Inventory.GetClass("inv_meta", "backpack")
if not bp then error("Something went wrong while loading Permanent inventory: backpack is missing.") return end

local prm = Inventory.Inventories.Permanent or bp:extend()

prm.SQLName = "ply_permainv"
prm.NetworkID = 3
prm.Name = "Permanent"
prm.MaxItems = 50

local pad = 12

local function determinePos(main, new)

	local w = main:GetWide()

	local tooright = main.X + w + pad + new:GetWide() > ScrW()
	local toX = 0
	if tooright then toX = -pad - new:GetWide() else toX = w + pad end

	return toX
end

prm:On("OpenFrame", "OpenInventoryCharacter", function(self, main, invpnl)
	if not main:GetFull() then return end

	local x, y, w, h = main:GetArea()

	local new = main:AddInventoryPanel("InventoryCharacter", self, function(main, new)
		new:MoveRightOf(main, 8)
	end)

	new:SetMainFrame(main)

	new:MoveRightOf(main, 8)
	new.Y = main.Y + main:GetTall() / 2 - new:GetTall() / 2
	main:AreaChanged(x, y, w, h)

end)

prm:On("CanAddItem", "EquippableOnly", function(self, it)
    return false
end)

prm:On("CanCreateItem", "EquippableOnly", function(self, iid, dat, slot)
	local base = Inventory.Util.GetBaseMeta(iid)
	print("returning", base.IsEquippable, base.ClassName, "EEEE")
	_AAA = base
    return base.IsEquippable
end)

prm:Register()