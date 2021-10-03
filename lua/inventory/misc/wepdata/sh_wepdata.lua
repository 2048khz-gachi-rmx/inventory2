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
	if wdt.EntPool[what] then return wdt.EntPool[what] end

	if IsEntity(what) then
		wdt.EntPool[what] = wdt.Pool[what:EntIndex()]
		return wdt.EntPool[what]
	elseif isnumber(what) then
		return wdt.Pool[what]
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