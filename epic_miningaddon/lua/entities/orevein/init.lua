AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


ENT.Model = "models/props/cs_militia/militiarock0%s.mdl"

OreRespawnTime = 300 --seconds


local sizes = {
	[1] = 3,
	[2] = 3,
	[3] = 2,
	[5] = 1
}

function ENT:Initialize()

	self:RandomizeStats()

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	self:DrawShadow(false)

	self.Ores = {}

	local phys = self:GetPhysicsObject()

	if (phys:IsValid()) then
		phys:Wake()
		phys:EnableMotion(true)
	end

	self:GenerateOres()

end

local drop_start = 0.5
local revdrop = 1 - drop_start
local curve = 2

local function sCurve(x) --x is 0-1

	if x >= drop_start then
		return drop_start + ( ((x - drop_start) ^ curve) / revdrop)
	end

	return x
end

function ENT:RandomizeStats()
	local rand = math.random(1, 4)
	if rand == 4 then rand = 5 end --lmao

	self:SetModel(string.format(self.Model, rand))
	self:PhysicsInit(SOLID_VPHYSICS)

	local min, max = 100, 0

	for k,v in pairs(Inventory.Mineables) do
		min = math.min(min, v:GetMinRarity())
		max = math.max(max, v:GetMaxRarity())
	end

	local rar = math.random(min, max)
	local diff = max - min

	relative = (rar - min) / diff

	self.Rarity = math.Round(min + sCurve(relative) * diff)	-- determines WHAT ORES spawn

	self.Richness = math.random(20, 100)	-- determines HOW MUCH OF EVERY ORE will spawn
	self.Purity = math.random(20, 80)		-- determines HOW PURE the ore will be

	local size = sizes[rand] or 1
	self.Diversity = size 					-- determines HOW MANY DIFFERENT ORES there will be
end

function ENT:FindConflicts(fin, confl)

end

function ENT:ApplyOres(tbl)

end

function ENT:GenerateOres(tries)
	tries = tries or 0

	if tries > 5 then
		printf("GenerateOres: try #%d !!!!!!", tries)
	end
	if tries >= 20 then
		self:Remove()
		error("This is getting ridiculous.")
	end

	table.Empty(self.Ores)

	local randem = {}
	local ranlen = 0

	for name, item in pairs(Inventory.Mineables) do
		local min, max = item:GetMinRarity(), item:GetMaxRarity()
		local rar = self.Rarity --rrarr
		if rar < min or rar > max then continue end --nyope

		ranlen = ranlen + 1
		randem[ranlen] = item
	end

	table.Shuffle(randem)
	-- from hereon we have a table of ores in a random order
	-- that can potentially spawn because rarity

	-- now fill in a pool of weights
	-- weight determines what chance the ore has to even be picked over others
	-- after that it'll roll an appear chance to see if it'll appear

	local pool = {}
	local sum = 0

	for k, it in ipairs(randem) do
		local ch = it:GetWeight()

		pool[k] = ch
		sum = sum + ch
	end

	-- now we have a table: {[1] = 50, [2] = 20, ...}
	-- which means: first 50 units will be ore #1, units 51-70 will be ore #2, etc...
	-- whatever ore we pick we just table.remove and sub that value from the sum

	local spawned = {} --table of ores that will come out after the spawn chances are done

	local ores = self.Diversity

	--printf("Spawning %d ores, pool length: #%d", ores, #pool)
	local i = 0
	while #spawned < ores and #pool > 0 do
		i = i + 1
		--printf("Loop #%d, current ores: %d", i, #spawned)
		local weight = math.random(1, sum)
		local cur = 0

		for k,v in ipairs(pool) do
			cur = cur + v
			if weight > cur then continue end

			local ore = randem[k]

			local chance = math.random(1, 100)

			if ore:GetSpawnChance() and chance > ore:GetSpawnChance() then --the ore isn't guaranteed to appear: roll the dice
				--we didn't pass

				local remweight = table.remove(pool, k)
				table.remove(randem, k)
				sum = sum - remweight
				break
			end

			-- we passed the spawn chance or there wasn't one: add the ore to spawned ores
			spawned[#spawned + 1] = ore

			local remweight = table.remove(pool, k)
			table.remove(randem, k)
			sum = sum - remweight
			break
		end

	end

	if #spawned == 0 then 		--yikes, the only weighted ores we got didn't pass the appear roll
		self:RandomizeStats() 	--re-roll our rarity and try again
		self:GenerateOres(tries + 1)
	else
		--now we randomize the ore richness
		self:RandomizeOreRichness(spawned)
		self:NetworkOres()
	end

end

local minrich = 0.1 --every ore will have AT LEAST 15% of total richness assigned to it

-- https://discordapp.com/channels/565105920414318602/567617926991970306/727510423460642816
-- ty based cornerpin once again

local function sumTo(count, targetSum)
	local values = {}
	local sum = 0

	for i = 1, count do
		local n = math.random()
		values[i] = n
		sum = sum + n
	end

	sum = sum / (targetSum - minrich * count)

	for i, n in ipairs(values) do
		values[i] = math.Round( n / sum + minrich, 2 )
	end

	return values
end

function ENT:RandomizeOreRichness(ores)
	local a = sumTo(#ores, 1)
	local rich = self.Richness
	--print("vein richness:", rich)
	--print("vein rarity:", self.Rarity, "\n")
	local result = {}

	for i=1, #ores do
		local ore = ores[i]
		local cost = ore:GetCost()
		--print("cost for", ore:GetName(), cost)
		local amt = math.ceil(a[i] * rich / cost)
		--print("	spawned:", amt)
		result[ore:GetItemName()] = {ore = ore, amt = amt}
	end

	self.Ores = result

	--self:SetStartingRichness(rich)
	return result

end

function ENT:NetworkOres()
	local t = {}
	for name, dat in pairs(self.Ores) do
		t[#t + 1] = {dat.ore:GetItemID(), dat.amt}
	end

	self:SetResources(math.random(500, 1000))
	--self:SetResources(von.serialize(t))
end

function OresRespawn()

end

if CurTime() > 60 then
	OresRespawn()
else

	local invready = false
	local entsready = false

	hook.Add("OnInvLoad", "SpawnOres", function()	--only after inventory is ready
		if entsready then OresRespawn() end
		invready = true
	end)

	hook.Add("InitPostEntity", "SpawnOres", function()
		if invready then OresRespawn() end
		entsready = true
	end)
end