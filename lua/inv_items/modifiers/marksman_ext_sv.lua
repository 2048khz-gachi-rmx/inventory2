--

local mxTrack = {}
local el = Inventory.Modifiers.Pool.Marksman

local makeTimer

el:Hook("EntityTakeDamage", function(self, ent, dmg)
		if not ent:IsPlayer() then return end

		local str, cap = self:GetTierStrength(self:GetTier())
		if not str then return end

		local bonus = math.Clamp(str * (self._marksmanHits - 1), 0, cap) / 100 + 1
		print("bonus", bonus)
		dmg:ScaleDamage(bonus)
	end)

hook.Add("ArcCW_BulletLanded", "MarksmanMod", function(wep, pen)
	local ow = wep:GetOwner()
	if not IsPlayer(ow) then return end

	local wdat = wep:GetWeaponData()
	if not wdat then return end

	local mods = wdat:GetMods()
	if not mods[el:GetName()] then return end

	local mod = mods[el:GetName()]

	local has_ply = false
	local maxDmg = 0

	local add, stk = mod:GetTierStrength(mod:GetTier())
	local maxHits = stk / add

	local msh = mod._marksmanHits or 0

	for eid, dmg in pairs(pen) do
		if Entity(eid):IsPlayer() and dmg > 0 then
			msh = math.min(
				msh + 1,
				maxHits + 1
			)

			mod._maxHits = maxHits
			mod._lastMarksman = CurTime()
			has_ply = true
		else
			maxDmg = math.max(maxDmg, dmg)
		end
	end

	if maxDmg == 0 then
		maxDmg = wep:GetDamage(128, true)
	end

	if not has_ply then
		msh = math.max(0, (msh or 0) - math.min(1.5, maxDmg / 25))
	end

	mod._marksmanHits = msh
	mxTrack[wep] = mod
	wep:SetNW2Float("MarksmanHits", mod._marksmanHits)

	makeTimer()
end)

local decayTime = 3

local function doDecay()
	if table.IsEmpty(mxTrack) then timer.Remove("MarksmanDecay") return end

	for wep, mod in pairs(mxTrack) do
		if not wep:IsValid() then mxTrack[wep] = nil continue end

		local msh = mod._marksmanHits
		local when = mod._lastMarksman
		local passed = CurTime() - when

		if passed > decayTime then
			local decPassed = passed - decayTime
			mod._lastMarksman = when + decPassed

			msh = math.max(0, math.min(mod._maxHits, msh) - decPassed)
			mod._marksmanHits = msh
			wep:SetNW2Float("MarksmanHits", mod._marksmanHits)

			if msh == 0 then
				mxTrack[wep] = nil
			end
		end
	end
end

function makeTimer()
	timer.Create("MarksmanDecay", 0.1, 0, doDecay)
end