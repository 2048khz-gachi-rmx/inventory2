--

Inventory.WeaponData = Inventory.WeaponData or Emitter:callable()

local wd = Inventory.WeaponData

function wd:Initialize(id)
	self.NW = Networkable("WD:" .. id)
	self.Networakble = self.NW
	self.Networakble.WeaponData = self

	local nw = self.NW

	nw:Alias("Stats", 0)
	nw:Alias("Mods", 1)
	nw:Alias("Ents", 2)

	self.Stats = {}
	self.Mods = {}

	self:RealmInit(id)
end

function wd:SetStats(t)
	for k,v in pairs(t) do
		self.Stats[k] = v
	end

	self.NW:Set("Stats", self.Stats)
end

include(Rlm(true) .. "_wepdata_ext.lua")