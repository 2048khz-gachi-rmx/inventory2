local wd = Inventory.WeaponData

function wd:RealmInit(id)
	self.NW:On("WriteChangeValue", "WeaponDataProxy", function(...)
		self:WriteData(...)
	end)
end

function wd:WriteData(nw, k, v, plys)
	if self["Serialize" .. k] then
		local ns = netstack:new()
		self["Serialize" .. k] (self, v, ns)

		net.WriteNetStack(ns)
		return false
	end

	print("no serialize function found for", k)
end

function wd:SerializeStats(stats, ns)
	print("Serializing stats")

	ns:WriteUInt(table.Count(stats), 8)
	for k,v in pairs(stats) do
		local enum = Inventory.Enums.WeaponStatsKeys[k]
		if not enum then errorf("No enum found for stat %q", k) return end

		ns:WriteUInt(enum, 8)
		ns:WriteFloat(v)
	end
end