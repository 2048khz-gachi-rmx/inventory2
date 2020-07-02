include("shared.lua")

local me = {}

function ENT:Initialize()
	if self:GetResources() > 0 then --bweh
		print("called UpdateOres from initialize:", self:GetResources())
		self:UpdateOres(nil, "from init; none", self:GetResources())
	end


end


function ENT:UpdateOres(_, old, new)
	print("-----\nself:", self, "\nold:", old, "\nnew:", new)
	print(self.What, self:GetClass(), self.IsOre, self:GetPos())
	if new ~= 0 and (new < 500 or new > 1000) then
		error("bad")
	end

	if true then return end
	--[[if new:sub(1, 1) ~= "{" then
		-- https://discordapp.com/channels/565105920414318602/589120351238225940/727586576552558683
		-- in the gmod discord

		print("if you see this, blame the gmod devs")
		return
	end]]

	local rec = von.deserialize(new)
	local ores = {}
	local fullamt = 0
	for k,v in ipairs(rec) do
		local id = v[1]
		local amt = v[2]

		local base = Inventory.Util.GetBase(id)
		fullamt = fullamt + amt * base:GetCost()
		ores[base:GetItemName()] = {ore = base, amt = amt}
	end

	self.Ores = ores
	self.TotalAmount = fullamt
end

function ENT:Draw()
	self:DrawModel()

end
