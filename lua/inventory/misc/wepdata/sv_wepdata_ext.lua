local wd = Inventory.WeaponData.Object
local wdt = Inventory.WeaponData

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

function wd:SerializeQuality(qname, ns)
	ns:WriteUInt(self:GetQuality():GetID(), 16)
end

function wd:SerializeStats(stats, ns)
	ns:WriteUInt(table.Count(stats), 8)

	for k,v in pairs(stats) do
		local enum = Inventory.Enums.WeaponStatsKeys[k]
		if not enum then errorf("No enum found for stat %q", k) return end

		ns:WriteUInt(enum, 8)
		ns:WriteFloat(v)
	end
end

-- mods ban vadikus
function wd:SerializeMods(mods, ns)
	ns:WriteUInt(table.Count(self:GetModifiers()), 8)

	for k,v in pairs(self:GetModifiers()) do
		ns:WriteUInt(Inventory.Modifiers.NameToID(k), 8)
		ns:WriteUInt(v, 8)
	end
end

function wd:SetWeapon(wep)
	wep.WeaponData = self
	wdt.EIDToWD:Set(wep:EntIndex(), self:GetID())
	wdt.EntPool[wep] = self

	self.UsingWeapons = self.UsingWeapons or {}
	self.UsingWeapons[wep] = true

	if wep.RecalcAllBuffs then
		wep:RecalcAllBuffs()
	end
end

function wd:RemoveWeapon(wep)
	if wep.WeaponData == self then
		local eid = wep:EntIndex()
		if wdt.EIDToWD:Get(eid) == self:GetID() then
			wdt.EIDToWD:Set(eid, nil)
		end

		wep.WeaponData = nil
		wdt.EntPool[wep] = nil
	end

	self.UsingWeapons[wep] = nil

	if table.IsEmpty(self.UsingWeapons) then
		print("cleanup WD in 10")
		timer.Create("WDCleanup:" .. self:GetID(), 10, 1, function()
			if table.IsEmpty(self.UsingWeapons) then
				self:Remove()
				print("did cleanup")
			end
		end)
	end
end

hook.Add("EntityRemoved", "WeaponData", function(wep)
	if not wep.WeaponData then return end

	local wd = wep.WeaponData

	--wd:Remove()
	wd:RemoveWeapon(wep)
end)

hook.Add("BW_DropWeapon", "WeaponData", function(ply, wep, dropent)
	local wd = wep.WeaponData
	if not wd then return end

	wd:SetWeapon(dropent)
end)

hook.Add("BW_WeaponPickedUp", "WeaponData", function(dropent, wep, ply)
	local wd = dropent.WeaponData
	if not wd then return end

	wd:SetWeapon(wep)
end)