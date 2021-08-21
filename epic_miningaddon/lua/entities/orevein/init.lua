AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")


ENT.Model = "models/props/cs_militia/militiarock0%s.mdl"

local OreRespawnTime = 180 	--seconds
local OreInvisibleTime = 5 	-- has to be invisible for X to everyone to disappear
local OreVisibleTime = 120 	-- if it's X seconds past it's time to remove it'll be removed regardless of people seeing

local sizes = {
	[1] = 3,
	[2] = 3,
	[3] = 2,
	[5] = 1
}

ActiveOres = ActiveOres or {}

function ENT:Initialize()
	ActiveOres[#ActiveOres + 1] = self
	self.Ores = {}

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	self:DrawShadow(false)

	local phys = self:GetPhysicsObject()

	if (phys:IsValid()) then
		phys:Wake()
		phys:EnableMotion(true)
	end

	self:CallOnRemove("UntrackOre", function()
		table.RemoveByValue(ActiveOres, self)
	end)

	self.LastActivity = CurTime()
	self.LastThink = CurTime()
	self.InvisiblePVS = 0

	self:RandomizeStats()
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

function ENT:FullReroll() -- mostly a debug function
	self.Ores = {}
	self.LastActivity = CurTime()

	self:RandomizeStats()
	self:GenerateOres()
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

function ENT:RespawnElsewhere()
	OresRespawn(1) -- first spawn so our ore entity is counted towards proximity check
	self:Remove()  -- then respawn
end

function ENT:Think()
	local timeTillDespawn = OreRespawnTime - (CurTime() - self.LastActivity)

	local delta = CurTime() - self.LastThink
	self.LastThink = self.LastThink + delta

	if timeTillDespawn > 5 then
		local dur = math.min(timeTillDespawn - 1, OreRespawnTime - 1)
		self:NextThink(CurTime() + dur)
		return true
	else
		if timeTillDespawn < -OreVisibleTime then
			-- it's really time for us to go now
			self:RespawnElsewhere()
			return
		end

		if timeTillDespawn < 0 then
			-- it's approx. time to respawn; if we're invisible to everyone else for 5s we do it
			local plys = player.GetAll()

			for _, ply in ipairs(plys) do
				if self:TestPVS(ply) == true then
					self.InvisiblePVS = 0 --we're visible to someone
					self:NextThink(CurTime() + 0.5)
					return true
				end
			end

			self.InvisiblePVS = self.InvisiblePVS + delta

			if self.InvisiblePVS > OreInvisibleTime then
				self:RespawnElsewhere()
				return
			end

			self:NextThink(CurTime() + 1)
			return true
		end

	end
end

function ENT:GenerateOres(tries)
	tries = tries or 0

	if tries > 5 then
		printf("GenerateOres: try #%d !!!!!!", tries)
	end
	if tries >= 50 then
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
		self.InitialOres = table.Copy(self.Ores)
		self:NetworkOres(true)
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

function ENT:MineOut(orename, ply)
	local ore = self.Ores[orename]
	ore.amt = ore.amt - 1

	if ore.amt <= 0 then self.Ores[orename] = nil end

	ply.Inventory.Backpack:NewItemNetwork(orename)

	self.LastActivity = CurTime()

	if table.Count(self.Ores) == 0 then
		self:Remove()
	end
end

function ENT:NetworkOres(init)

	local t = {}
	for name, dat in pairs(self.Ores) do
		if not dat.ore:GetItemID() then -- safeguard
			errorf("Ore doesn't have ID!!! %s / %s / %s", dat.ore, dat.ore:GetName() or "no name", dat.ore:GetItemID() or "no id")
			return
		end

		t[#t + 1] = {dat.ore:GetItemID(), dat.amt}
	end

	self:SetResources(von.serialize(t))

	if init then
		local it = {}
		for name, dat in pairs(self.InitialOres) do
			it[#it + 1] = {dat.ore:GetItemID(), dat.amt}
		end

		self:SetInitialResources(von.serialize(t))
	end
end

local function readOreData()
	Inventory.OresPositions = Inventory.OresPositions or {}

	local dat = file.Read("inventory/ore_positions.dat", "DATA")
	if not dat then
		file.Write("inventory/ore_positions.dat", "")
		return
	end

	local poses = util.JSONToTable(dat)

	for k,v in ipairs(poses) do
		if not table.HasValue(Inventory.OresPositions, v) then	-- O(n^2) lets goooo
			Inventory.OresPositions[#Inventory.OresPositions + 1] = v
		end
	end

end

local function rollOrePos(num)
	num = num or 1

	local posCopy = table.Copy(Inventory.OresPositions)
	local ret = {}

	while #ret < num do
		local key = math.random(1, #posCopy)
		pos = posCopy[key]
		if not pos then break end

		for _, ent in ipairs(ActiveOres) do
			if ent:GetPos():DistToSqr(pos) < 4 then goto nextPos end -- we already have a rock at pretty much that location; reroll
		end

		if pos then
			ret[#ret + 1] = pos
		end

		::nextPos::
		table.remove(posCopy, key)
	end

	return ret
end

local entClass = "orevein"

local function createOre(pos)
	pos = pos or rollOrePos()
	if not pos then return end

	local ore = ents.Create(entClass)
	ore:SetPos(pos)
	ore:Spawn()

	ore:GetPhysicsObject():EnableMotion(false)
end

function OresRespawn(amt)
	for i=#ActiveOres, 1, -1 do
		local e = ActiveOres[i]
		if not e:IsValid() then table.remove(ActiveOres, i) end
	end

	amt = amt or 4 - #ActiveOres
	if amt <= 0 then return end

	if not Inventory.OresPositions then
		readOreData()
	end

	local spawns = rollOrePos(amt)

	for k,v in ipairs(spawns) do
		createOre(v)
	end
end

local function loadOres()
	Inventory.Ores = Inventory.Ores or {}

	Inventory.Ores.Create = createOre
	Inventory.Ores.RollPosition = rollOrePos

	Inventory.MySQL.WaitStates(OresRespawn, "itemids")
end

if CurTime() > 60 then
	loadOres()
else
	hook.Add("InventoryReady", "SpawnOres", loadOres)
end