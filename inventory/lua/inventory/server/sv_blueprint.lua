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
	[1] = function(ply) return math.random() > 0.85 and 1 or 0 end, --15% of 1 mod
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

function bp.GenerateMods(amt)
	local pool = Inventory.Modifiers.Pool
	local keys = table.GetKeys(pool)

	local ret = {}

	for i=1, amt do
		local modnum = math.random(1, #keys)
		local name = keys[modnum]
		if not name then break end

		local modtbl = pool[name]

		local tier = math.random(1, modtbl.MaxTier or 1)
		ret[name] = tier

		table.remove(keys, modnum)
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

function bp.Generate(tier, typ)
	if typ == "random" then
		typ = bp.GetRandomType()
	end

	local amtMods = bp.TierGetMods(tier)
	local wep = bp.GetWeapon(typ)
	print("generating", wep, amtMods)

	local mods = bp.GenerateMods(amtMods)

	local item = Inventory.Blueprints.CreateBlank()
	item:SetModifiers(mods)
	item:SetResult(wep)
	item:SetTier(tier)

	item:SetRecipe(bp.GenerateRecipe(item))

	return item
end