--

local wd = Inventory.WeaponData.Object

function wd:RealmInit(id)
	self.NW:On("ReadChangeValue", "WeaponDataProxy", function(...)
		self:ReadData(...)
	end)
end

function wd:ReadData(nw, key)
	if self["Deserialize" .. key] then
		print("calling Deserialize" .. key)
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


