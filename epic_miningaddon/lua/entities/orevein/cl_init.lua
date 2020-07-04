include("shared.lua")

local me = {}

function ENT:Initialize()
	if #self:GetResources() > 0 then --bweh
		print("called UpdateOres from initialize:", self:GetResources())
		self:UpdateOres(nil, "from init; none", self:GetResources())
	end


end


function ENT:UpdateOres(_, old, new)

	if #new > 0 and new:sub(1, 1) ~= "{" then
		-- https://discordapp.com/channels/565105920414318602/589120351238225940/727586576552558683
		-- in the gmod discord

		print("if you see this, blame the gmod devs")
		return
	end

	local rec = von.deserialize(new)
	local ores = self.Ores or {}
	local fullamt = 0

	local tick = FrameNumber()

	for k,v in ipairs(rec) do
		local id = v[1]
		local amt = v[2]

		local base = Inventory.Util.GetBase(id)
		fullamt = fullamt + (v[3] * base:GetCost())

		local ore = ores[base:GetItemName()] or {ore = base, startamt = v[3]} -- don't recreate table if it existed b4
		ore.amt = amt
		ore.tick = tick

		ores[base:GetItemName()] = ore
	end

	for k,v in pairs(ores) do
		if v.tick ~= tick then
			-- this ore wasn't included in the update; probably gone
			-- set amt to 0
			v.amt = 0
		end
	end

	self.Ores = ores

	if not self.TotalAmount then self.TotalAmount = fullamt end
end

function ENT:Draw()
	self:DrawModel()

end
