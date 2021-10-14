--

local eq = Inventory.GetClass("item_meta", "equippable")
local wep = Inventory.ItemObjects.Weapon or eq:Extend("Weapon")

BaseItemAccessor(wep, "WeaponClass", "WeaponClass")
BaseItemAccessor(wep, "Uses", "StartUses")

DataAccessor(wep, "Uses", "Uses")

function wep:Initialize()

end

function wep:InitializeNew()
	-- new weapons get uses set to starting automatically
	self:SetUses(self:GetStartUses())
end

local allowed = table.KeysToValues({"primary", "secondary", "utility"})

local gray = Color(100, 100, 100)


local sepPrePost = false

function wep:GenerateText(cloud, markup)
	cloud:SetMaxW( math.max(cloud:GetItemFrame():GetWide() * 2.5, cloud:GetMaxW()) )
	local needSep = self:GenerateStatsText(cloud, markup)
	needSep = self:GenerateModifiersText(cloud, markup, needSep)

	sepPrePost = needSep
end

function wep:PostGenerateText(cloud, markup)
	local uses = self:GetData().Uses
	if uses then
		if sepPrePost then
			cloud:AddSeparator(nil, cloud.LabelWidth / 8, 4)
		end
		cloud:AddFormattedText(uses .. " uses remaining", gray, "OS18", nil, nil, 1)
	end

	sepPrePost = false
end

wep:On("CanEquip", "WeaponCanEquip", function(self, ply, slot)
	local slotName = slot.slot

	local can, why = Inventory.CanEquipInSlot(self, slot)
	if can == false then return can, why end

	if not allowed[slotName] then
		return false, ("Not a possible weapon slot: '%s'"):format(slotName)
	end
	if self:GetInventory() and self:GetInventory():GetOwner() ~= ply then
		return false, ("Player is not owner: '%s' vs '%s'"):format(self:GetOwner(), ply)
	end
end)

wep:Register()



Inventory.ArcCW_InventoryAttachments = Inventory.ArcCW_InventoryAttachments or {}

local invOnly = {
	"fcg_accelerator", "gsob_fcg_accelerator",
	"fcg_auto", "gsob_fcg_auto",
	"go_homemade_auto",
	"gsoe_extra_perk_infinite",

	"gsob_ammo_api", "go_ammo_sg_dragon",
	"gsoe_extra_ammo_explosive",
	"fml_fas1_muzz_bayo_quad"
}

for k,v in ipairs(invOnly) do
	Inventory.ArcCW_InventoryAttachments[v] = true
end

hook.Add("ArcCW_PlayerCanAttach", "InventoryRestrict", function(ply, wep, att, slot, detach)
	if detach then return end
end)

include("weapon_" .. Rlm(true) .. "_extension.lua")
