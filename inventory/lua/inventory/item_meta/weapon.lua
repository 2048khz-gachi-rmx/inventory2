--

local eq = Inventory.GetClass("item_meta", "equippable")
local wep = Inventory.ItemObjects.Weapon or eq:Extend("Weapon")

BaseItemAccessor(wep, "WeaponClass", "WeaponClass")
BaseItemAccessor(wep, "Uses", "StartUses")
function wep:Equip(ply, slot)
	local mem = eq.Equip(self, ply, slot)

	local new = ply:Give(self:GetWeaponClass())
	if new ~= NULL then
		self:SetData("Uses", self:GetData().Uses - 1)
	end
	return mem
end

local allowed = table.KeysToValues({"primary", "secondary", "utility"})

wep:On("CreatedNew", "AssignUses", function(self)
	self:SetData("Uses", self:GetStartUses())
end)

local gray = Color(100, 100, 100)

wep:On("GenerateText", "Uses", function(self, cloud, mup)
	local uses = self:GetData().Uses
	if uses then
		cloud:AddFormattedText(uses .. " uses remaining", gray, "OS18")
	end
	--[[cloud:AddFormattedText("woah now this one is rly good!!!", Colors.Money)

	local p2 = mup:AddPiece()
	p2:SetFont("OSB20")

	p2:AddTag(MarkupTags("color", 150, 60, 200))
	local rand = function() return math.Rand(-0.55, 0.55) end

	local trind = p2:AddTag(MarkupTags("chartranslate", rand, rand))

	p2:AddText("[Menacing]")
	p2:EndTag(trind)]]
end)

wep:On("CanEquip", "WeaponCanEquip", function(self, ply, slot)
	local slotName = slot.slot

	local can, why = Inventory.CanEquipInSlot(self, slot)
	if can == false then return can, why end

	if not allowed[slotName] then return false, ("Not a possible weapon slot: '%s'"):format(slotName) end
	if self:GetInventory() and self:GetInventory():GetOwner() ~= ply then return false, ("Player is not owner: '%s' vs '%s'"):format(tostring(self:GetOwner()), tostring(ply)) end
end)

wep:Register()