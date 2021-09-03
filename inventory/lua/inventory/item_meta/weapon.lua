--

local eq = Inventory.GetClass("item_meta", "equippable")
local wep = Inventory.ItemObjects.Weapon or eq:Extend("Weapon")

BaseItemAccessor(wep, "WeaponClass", "WeaponClass")
BaseItemAccessor(wep, "Uses", "StartUses")

function wep:Initialize()
	self:SetModifiers({})
	self:SetData("Uses", self:GetStartUses())
end

function wep:Equip(ply, slot)
	local mem = eq.Equip(self, ply, slot)

	local new = ply:Give(self:GetWeaponClass())
	if new ~= NULL then
		self:SetData("Uses", self:GetData().Uses - 1)
	end
	return mem
end

local allowed = table.KeysToValues({"primary", "secondary", "utility"})

local gray = Color(100, 100, 100)

wep:On("GenerateText", "Uses", function(self, cloud, mup)
	local uses = self:GetData().Uses
	if uses then
		cloud:AddFormattedText(uses .. " uses remaining", gray, "OS18")
	end
end)

wep:On("CanEquip", "WeaponCanEquip", function(self, ply, slot)
	local slotName = slot.slot

	local can, why = Inventory.CanEquipInSlot(self, slot)
	if can == false then return can, why end

	if not allowed[slotName] then return false, ("Not a possible weapon slot: '%s'"):format(slotName) end
	if self:GetInventory() and self:GetInventory():GetOwner() ~= ply then return false, ("Player is not owner: '%s' vs '%s'"):format(tostring(self:GetOwner()), tostring(ply)) end
end)

ChainAccessor(wep, "Modifiers", "Modifiers")
ChainAccessor(wep, "Modifiers", "Mods")

wep:Register()

local invOnly = {
	"fcg_accelerator"
}

for k,v in ipairs(invOnly) do
	invOnly[v] = true
end

hook.Add("ArcCW_PlayerCanAttach", "InventoryRestrict", function(ply, wep, att, slot, detach)
	if detach then return end
end)


-- cl hook
hook.Add("ArcCW_ShouldShowAtt", "InventoryRestrict", function(att)
	if invOnly[att] then return false end
end)