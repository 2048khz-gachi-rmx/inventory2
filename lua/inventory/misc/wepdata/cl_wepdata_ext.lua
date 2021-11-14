--

local wd = Inventory.WeaponData.Object
local wdt = Inventory.WeaponData

function wd:RealmInit(id)
	self.NW:On("ReadChangeValue", "WeaponDataProxy", function(...)
		self:ReadData(...)
	end)

	for k,v in pairs(wdt.EIDToWD:GetNetworked()) do
		if v == id then
			self:ResetWeaponBuffs(Entity(k))
			wdt.EntPool[k] = self
			wdt.EntPool[Entity(k)] = self
		end
	end
end

function wd:ReadData(nw, key)
	print("ReadData:", nw, key)

	if self["Deserialize" .. key] then
		return self["Deserialize" .. key] (self)
	end
end

function wd:DeserializeQuality()
	local q = net.ReadUInt(16)
	local ql = Inventory.Qualities.Get(q)

	self:SetQuality(ql)
end

function wd:DeserializeStats()
	local amt = net.ReadUInt(8)

	for i=1, amt do
		local num = net.ReadUInt(8)
		local perc = net.ReadFloat()

		local name = Inventory.Enums.WeaponIDToStat(num)

		self.Stats[name] = perc
	end
end

function wd:DeserializeMods()
	local mods = net.ReadUInt(8)
	local out = {}

	for i=1, mods do
		local id = net.ReadUInt(8)
		local name = Inventory.Modifiers.IDToName(id)
		local tier = net.ReadUInt(8)

		out[name] = tier
	end

	self:SetMods(out)
end

wdt.EIDToWD:On("NetworkedVarChanged", "RecalcBuffs", function(self, key, old, new)
	if isnumber(new) then
		local ent = Entity(key)
		local wd = wdt.Get(new)

		if wd then
			wd:ResetWeaponBuffs(ent)
			wdt.EntPool[key] = wd
			wdt.EntPool[ent] = wd
		end
	end
end)