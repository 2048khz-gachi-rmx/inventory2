--

Inventory.WeaponData = Inventory.WeaponData or {}
local wdt = Inventory.WeaponData

wdt.Pool = wdt.Pool or {}
wdt.EntPool = wdt.EntPool or WeakTable()

wdt.Object = wdt.Object or Emitter:callable()

local wd = Inventory.WeaponData.Object

wdt.EIDToWD = wdt.EIDToWD or Networkable("eidToWD")


local function nwAccessor(t, key, func)
	t["Get" .. func] = function(self)
		return self[key]
	end

	t["Set" .. func] = function(self, val)
		self[key] = val
		self.NW:Set(func, val)
		return self
	end
end

nwAccessor(wd, "Quality", "Quality")
nwAccessor(wd, "Mods", "Mods")
nwAccessor(wd, "Mods", "Modifiers")
nwAccessor(wd, "Stats", "Stats")
ChainAccessor(wd, "ID", "ID")

function wd:SetMods(tbl)
	for name, tier in pairs(tbl) do
		if not Inventory.Modifiers.Pool[name] then
			errorNHf("Unrecognized modifier when setting to WD: %q")
			continue
		end

		local mod = Inventory.Modifier:new(name)
		mod:SetTier(tier)
		mod:SetWD(self)

		self.Mods[name] = mod
	end

	self.NW:Set("Mods", tbl)
end
wd.SetModifiers = wd.SetMods

function wd:Initialize(id)
	self.NW = Networkable("WD:" .. id)
	self.Networkable = self.NW
	self.Networkable.WeaponData = self

	local nw = self.NW

	nw:Alias("Stats", 0)
	nw:Alias("Mods", 1)
	nw:Alias("Ents", 2)
	nw:Alias("Quality", 3)

	self.Stats = {}
	self.Mods = {}
	self:SetID(id)

	self:RealmInit(id)

	wdt.Pool[id] = self
	wdt.EntPool[id] = self
end

function wd:ResetWeaponBuffs(wep)
	if IsWeapon(wep) and wep.RecalcAllBuffs then
		wep:RecalcAllBuffs()
	end
end

function wd:SetStats(t)
	for k,v in pairs(t) do
		self.Stats[k] = v
	end

	self.NW:Set("Stats", self.Stats)
end

function wd:Remove()
	self.NW:Invalidate()
	self._Valid = false

	wdt.Pool[self:GetID()] = nil
	for k,v in pairs(wdt.EntPool) do
		if v == self then wdt.EntPool[k] = nil end
	end

	for k,v in pairs(self:GetMods()) do
		v:Remove()
	end

	self:Emit("Remove")
end

function wd:IsValid()
	return self._Valid ~= false
end

include(Rlm(true) .. "_wepdata_ext.lua")

hook.Add("NetworkableAttemptCreate", "WeaponData", function(id)
	if not tostring(id):match("^WD:") then return end
	wd:new(tonumber(id:match("WD:(%d+)")))
	return true
end)

function wdt.Get(what)
	local qret = wdt.EntPool[what]
	if qret and qret:IsValid() then return qret end

	if IsEntity(what) then
		local ret = wdt.Pool[what:EntIndex()]
		if not ret or not ret:IsValid() then return false end

		wdt.EntPool[what] = ret
		return wdt.EntPool[what]
	elseif isnumber(what) then
		local ret = wdt.Pool[what]
		return ret and ret:IsValid() and ret
	end
end

-- arccw stat -> inventory stat
local conv = {
	AccuracyMOA = "Spread", -- higher AccuracyMOA = more inaccurate
	SightTime = "Handling",
	SpeedMult = "MoveSpeed",
}

-- called once

function Inventory.DoBuffMult(wep, key, cur)
	local wd = wdt.Get(wep)
	if not wd then return end

	key = key:gsub("^Mult_", "")
	key = conv[key] or key
	local perc = 1 + (wd:GetStats()[key] or 0) / 100

	for k,v in pairs(wd:GetMods() or {}) do
		local st = v:GetModStats()
		if not st or (not st[key] and not st.Any) then continue end

		local str = eval(st[key] or st.Any, v, key)
		if str then
			perc = perc + str / 100
		end
	end

	return perc
end


-- DISABLED:

function Inventory.DoBuffAdd(wep, key, cur)
	do return end

	local wd = wdt.Get(wep)
	if not wd then return end

	key = key:gsub("^Add_", "")
	key = conv[key] or key
end

-- called a buncha times all the time
function Inventory.DoBuffHook(wep, key, data)
	do return end

	local wd = wdt.Get(wep)
	if not wd then return end

	key = key:gsub("^Mult_", "")
	-- ???
end

local ENTITY = FindMetaTable("Entity")

function ENTITY:GetWeaponData()
	local wdid = wdt.EIDToWD:Get(self:EntIndex())
	if wdid then
		return wdt.Get(wdid)
	end
end

function ENTITY:HasModifier(name)
	if not self:IsValid() then return false end
	local wd = self:GetWeaponData()
	if not wd then return false end

	return wd:GetMods() [name]
end