--
local wep = Inventory.ItemObjects.Weapon

hook.Add("ArcCW_ShouldShowAtt", "InventoryRestrict", function(att)
	if Inventory.ArcCW_InventoryAttachments[att] then return false end
end)

function wep:GetRarityColor()
	return self:GetQuality():GetColor()
end

function wep:GetRarityText()
	local fmt = "%s %s"
	return fmt:format(self:GetQuality():GetName(),
		Inventory.EquippableName(self:GetEquipSlot()))
end

local gray = Color(100, 100, 100)


local sepPrePost = false

function wep:GenerateText(cloud, markup)
	sepPrePost = Inventory.ItemObjects.Unique.GenerateText(self, cloud, markup)
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

function wep:GenerateOptions(mn)
	local inv = self:GetInventory()
	if inv ~= Inventory.GetTemporaryInventory(CachedLocalPlayer()) then return end

	local opt = mn:AddOption("Use")
	opt.HovMult = 1.15
	opt.Color = Colors.Sky:Copy()
	opt.DeleteFrac = 0
	opt.Description = "Spend a charge to equip this weapon"

	local item = self

	function opt:DoClick()
		local ns = Inventory.Networking.Netstack()
			ns:WriteInventory(inv)
			ns:WriteItem(item, true)
		Inventory.Networking.PerformAction(INV_ACTION_USE, ns)
	end
end