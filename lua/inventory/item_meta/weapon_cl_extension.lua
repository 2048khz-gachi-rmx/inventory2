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
	cloud:SetMaxW( math.max(cloud:GetItemFrame():GetWide() * 2.5, cloud:GetMaxW()) )
	self:GenerateRarityText(cloud, markup)

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