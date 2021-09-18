--

local gen = Inventory.GetClass("item_meta", "generic_item")
local uq = Inventory.ItemObjects.Unique or gen:Extend("Unique")

DataAccessor(uq, "QualityName", "QualityName")
DataAccessor(uq, "Stats", "StatRolls") -- stats contained in data are merely rolls 0-1 for their strengths
DataAccessor(uq, "Modifiers", "ModNames") -- mods contained in data are just {[name] = tier} values

function uq:GetStats(tbl)
	local into = tbl or {}
	local qualStats = self:GetQuality().Stats
	for k,v in pairs(self:GetStatRolls()) do
		if not qualStats[k] then continue end
		into[k] = Lerp(v, unpack(qualStats[k]))
	end

	return into
end

function uq:GetModifiers(tbl)
	local into = tbl or {}

	--[[for name, tier in pairs(self:ModNames()) do
		into[Inventory.Modifiers.Get(name)] = tier
	end]]

	-- eh maybe just copy the names? autorefresh friendly?
	for name, tier in pairs(self:GetModNames()) do
		into[name] = tier
	end

	return into
end

function uq:GetQuality()
	return Inventory.Qualities.Get(self:GetQualityName())
end

function uq:SetQuality(ql)
	self:SetQualityName(Inventory.Qualities.Get(ql):GetName())
end

function uq:GetName()
	return ("%s %s"):format(
		self:GetQuality() and self:GetQuality():GetName() or "Mundane", gen.GetName(self)
	)
end

uq:Register()

include("unique_item_" .. Rlm(true) .. "_extension.lua")
