Inventory.Blueprints = Inventory.Blueprints or {}

local zeroClamp = function(a)
	return math.max(a, 0)
end

local chances = {
	pistol = 1.25,
	--shotgun = 1.1,
	sr = 0.75,
	dmr = 0.75,
	smg = 1.1,
}

Inventory.Blueprints.TierMods = {
	[1] = function(ply) return math.random() > 0.0 and 1 or 0 end, --15% of 1 mod
	[2] = function(ply) return math.random() > 0.75 and 2 or 1 end, --75% of 1 mod, 25% of 2 mods

	[3] = function(ply)
		-- 20% of 1 mod, 60% of 2 mods, 20% of 3 mods
		return math.ceil(zeroClamp(math.random() - 0.2) / 0.6) + 1
	end,

	[4] = function(ply)
		--30% of 2 mods, 50% of 3 mods, 20% of 4 mods
		return math.ceil(zeroClamp(math.random() - 0.3) / 0.5) + 2
	end,

	[5] = 4, --also has a talent
}

local bp = Inventory.Blueprints

function bp.TierHasTalent(tier)
	return tier >= 5
end

function bp.GetWeapon(typ, tier) --weapon pools are defined in sh_blueprints.lua
	local pool = bp.WeaponPool[typ]
	if not pool then print("Failed to get blueprint pool for weapon type:", typ) return end --?

	local available = {}

	for k,v in ipairs(pool) do
		local base = Inventory.BaseItems[v]
		if not base then
			errorNHf("Missing weapon while generating blueprint: %s!", v)
			continue
		end

		if base:CanGenerate(tier) then
			available[#available + 1] = v
		end
	end

	if #available == 0 then
		errorf("No available weapons for type %s, tier %s!", typ, tier)
		return
	end

	local rand = math.random(1, #available)
	return available[rand]
end

function bp.TierGetMods(tier)
	return eval(Inventory.Blueprints.TierMods[tier])
end

function bp.GetRandomType()
	local typs = {}
	local total = 0
	for name, dat in pairs(Inventory.Blueprints.Types) do
		local chance = dat.Chance or chances[name] or 1

		if name == "Random" then continue end
		if not bp.WeaponPool[name] then continue end --??

		typs[#typs + 1] = {name, total + chance}
		total = total + chance
	end

	local frac = math.random() * total

	for k,v in pairs(typs) do
		if v[2] > frac then
			return v[1]
		end
	end
end

function bp.GenerateMods(tier, qual, amt)
	local pool = {}
	local guar = {} -- guaranteed mods

	local ret = {}
	local count = 0

	for k,v in pairs(Inventory.Modifiers.Pool) do
		if qual.ModsBlacklist[k] then continue end
		if v:GetRetired() then continue end
		if tier < (v:GetMinBPTier() or 0) then continue end

		if qual.ModsGuarantee[k] then
			guar[#guar + 1] = v
		else
			pool[#pool + 1] = v
		end
	end

	table.Shuffle(guar)

	for i=1, math.min(amt, #guar) do
		local modtbl = guar[i]
		local tier = math.random(1, modtbl:GetMaxTier() or 1)
		ret[modtbl:GetName()] = tier
		count = count + 1
	end

	if count == amt then return ret end

	table.Shuffle(pool)

	for i=1, math.min(amt - count, #pool) do
		local modtbl = pool[i]
		local tier = math.random(1, modtbl:GetMaxTier() or 1)
		ret[modtbl:GetName()] = tier
		count = count + 1
	end

	return ret
end

function bp.GenerateStats(qual)
	local copy = {} -- shallow copy
	local i = 1
	for k,v in pairs(qual.Stats) do
		copy[i] = k
		i = i + 1
	end

	local ret = {}

	for k,v in pairs(qual.StatsGuarantee) do
		ret[k] = math.random()
		table.RemoveByValue(copy, k)
	end

	local max = math.min(qual:GetMaxStats() or 999, #copy)
	local min = math.min(qual:GetMinStats() or 0, max)

	local amt = math.random(min, max)

	for i=1, amt do
		local k = copy[i]
		ret[k] = math.random()
	end

	return ret
end

function bp.GenerateRecipe(itm)
	local tier = itm:GetTier()
	local wep = itm:GetResult()
	local mods = itm:GetModifiers()

	local rec = {}

	if tier == 1 then
		rec.copper_bar = math.random(5, 15)
		rec.iron_bar = math.random(10, 20)
		rec.nutsbolts = math.random(1, 4)
		rec.adhesive = math.random(1, 2)

	elseif tier == 2 then
		rec.copper_bar = math.random(5, 15)
		rec.iron_bar = math.random(10, 20)
		rec.gold_bar = math.random(5, 10)
		rec.nutsbolts = math.random(3, 7)
		rec.adhesive = math.random(2, 4)
		rec.lube = math.random(1, 2)

	elseif tier == 3 then
		rec.copper_bar = math.random(20, 60)
		rec.iron_bar = math.random(30, 75)
		rec.gold_bar = math.random(15, 30)
		rec.nutsbolts = math.random(6, 13)
		rec.adhesive = math.random(4, 7)
		rec.lube = math.random(1, 2)

		for k,v in pairs(mods) do
			Inventory.Modifiers.Get(k):Emit("AlterRecipe", itm, rec, v)
		end
	else
		rec.copper_bar = 9999
	end

	return rec
end

function bp.PickQuality(tier, wep)
	local quals = Inventory.Qualities.ByTier[tier]

	local pool = {}
	for k,v in ipairs(quals) do pool[k] = v end

	while true do
		local key = math.random(#pool)
		local pick = pool[key]
		if not pick then return false end -- ran out of mods in pool

		if pick:GetType() == "Weapon" then return pick end
		table.remove(pool, key)
	end
end

function bp.Generate(tier, typ)
	if typ == "random" then
		typ = bp.GetRandomType()
	end

	local wep = bp.GetWeapon(typ, tier)

	local qual = bp.PickQuality(tier, wep)
	local amtMods = bp.TierGetMods(tier)
	local mods = bp.GenerateMods(tier, qual, amtMods)
	local stats = bp.GenerateStats(qual)

	local item = Inventory.Blueprints.CreateBlank()
	item:SetResult(wep)
	item:SetTier(tier)

	item:SetQualityName(qual:GetName())
	item:SetModNames(mods)
	item:SetStatRolls(stats)

	item:SetRecipe(bp.GenerateRecipe(item))

	return item
end

function bp.DebugGenerate(tier, mods, stats, qual, rec)
	local typ = bp.GetRandomType()
	local wep = bp.GetWeapon(typ, tier)

	if mods then
		for k,v in pairs(mods) do
			if not Inventory.Modifiers.Get(k) then
				errorf("No such modifier: %s", k)
			end

			if not isnumber(v) then
				errorf("Invalid format (should be [\"ModName\"] = tier)")
			end
		end
	end

	if stats then
		for k,v in pairs(stats) do
			if not Inventory.Stats.ToName(v) then
				errorf("No such stat: %s", v)
			end
		end
	end

	if qual and not Inventory.Qualities.Get(qual) then
		errorf("No such quality: %s", qual)
	end

	local amtMods = bp.TierGetMods(tier)

	qual = qual or bp.PickQuality(tier, wep)
	mods = mods or bp.GenerateMods(tier, qual, amtMods)
	stats = stats or bp.GenerateStats(qual)

	local item = Inventory.Blueprints.CreateBlank()
	item:SetResult(wep)
	item:SetTier(tier)

	item:SetQualityName(qual:GetName())
	item:SetModNames(mods)
	item:SetStatRolls(stats)

	if rec ~= false then
		item:SetRecipe(bp.GenerateRecipe(item))
	else
		item:SetRecipe({})
	end

	return item
end