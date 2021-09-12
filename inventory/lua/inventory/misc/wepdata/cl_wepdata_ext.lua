--
local wd = Inventory.WeaponData

function wd:RealmInit(id)
	self.NW:On("ReadChangeValue", "WeaponDataProxy", function(...)
		self:ReadData(...)
	end)
end

function wd:ReadData(nw, key)
	if self["Deserialize" .. key] then
		return self["Deserialize" .. key] (self)
	end
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