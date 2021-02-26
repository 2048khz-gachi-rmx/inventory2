include("shared.lua")

local me = {}

function ENT:Initialize()
	--self:CheckDTs()

	self.Ores = {}
	self.InitialOres = {}
end

function ENT:DecodeCurrentResources(new)
	local rec = von.deserialize(new)

	table.Empty(self.Ores)
	local ores = self.Ores

	for k,v in ipairs(rec) do
		local id = v[1]
		local amt = v[2]

		local base = Inventory.Util.GetBase(id)
		if not base then ErrorNoHalt("Failed to find ore ID @ " .. (id or "No ID?") .. "\n" .. new .. "\n") continue end

		local ore = ores[base:GetItemName()] or {ore = base, amt = amt} -- don't recreate table if it existed b4

		ores[base:GetItemName()] = ore
	end

end

function ENT:DecodeInitialResources(new)
	local rec = von.deserialize(new)
	local fullamt = 0

	table.Empty(self.InitialOres)
	local ores = self.InitialOres

	for k,v in ipairs(rec) do
		local id = v[1]
		local amt = v[2]

		local base = Inventory.Util.GetBase(id)
		if not base then ErrorNoHalt("Failed to find ore ID @ " .. (id or "No ID?") .. "\n" .. new .. "\n") continue end

		fullamt = fullamt + (amt * base:GetCost())

		local ore = ores[base:GetItemName()] or {ore = base, amt = amt} -- don't recreate table if it existed b4
		ore.amt = amt

		ores[base:GetItemName()] = ore
	end

	self.TotalAmount = fullamt 
end

function ENT:UpdateOres(key, old, new)
	if not isstring(new) then return end

	if #new > 0 and new:sub(1, 1) ~= "{" then
		error("if you see this, blame the gmod devs: " .. new)
		return
	end

	if key == "Resources" then
		self:DecodeCurrentResources(new)
	elseif key == "InitialResources" then
		self:DecodeInitialResources(new)
	end
end

ENT.OnDTChanged = ENT.UpdateOres

function ENT:Draw()
	self:DrawModel()
end
