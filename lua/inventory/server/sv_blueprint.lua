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

function bp.GetWeapon(typ) --weapon pools are defined in sh_blueprints.lua
	local pool = bp.WeaponPool[typ]
	if not pool then print("Failed to get blueprint pool for weapon type:", typ) return end --?

	local rand = math.random(1, #pool)
	return pool[rand]
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

function bp.GenerateMods(qual, amt)
	local pool = {}
	local guar = {} -- guaranteed mods

	local ret = {}
	local count = 0

	for k,v in pairs(Inventory.Modifiers.Pool) do
		if not qual.ModsBlacklist[k] then
			if qual.ModsGuarantee[k] then
				guar[#guar + 1] = v
			else
				pool[#pool + 1] = v
			end
		end
	end

	table.Shuffle(guar)

	print("Generating:", qual:GetName(), amt)
	for i=1, math.min(amt, #guar) do
		ret[guar[i]:GetName()] = guar[i]
		count = count + 1
	end

	print("GENERATED GUARANTEED MODS:")
	PrintTable(table.GetKeys(ret))

	if count == amt then return ret end

	table.Shuffle(pool)

	for i=1, math.min(amt - count, #pool) do
		local modtbl = pool[i]
		local tier = math.random(1, modtbl:GetMaxTier() or 1)
		ret[modtbl:GetName()] = tier
		count = count + 1
	end

	print("GENERATED MODS:")
	PrintTable(table.GetKeys(ret))

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
	elseif tier == 2 then
		rec.copper_bar = math.random(5, 15)
		rec.iron_bar = math.random(10, 20)
		rec.gold_bar = math.random(5, 10)
	else
		rec.copper_bar = 999
		rec.iron_bar = 999
		rec.gold_bar = 999
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

	local wep = bp.GetWeapon(typ)

	local qual = bp.PickQuality(tier, wep)
	local amtMods = bp.TierGetMods(tier)
	local mods = bp.GenerateMods(qual, amtMods)

	local item = Inventory.Blueprints.CreateBlank()
	item:SetModifiers(mods)
	item:SetResult(wep)
	item:SetTier(tier)

	item:SetRecipe(bp.GenerateRecipe(item))

	return item
end