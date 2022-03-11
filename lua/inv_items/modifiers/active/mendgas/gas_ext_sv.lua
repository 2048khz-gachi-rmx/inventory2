--

local areas = {}
local el = Inventory.Modifiers.Get("MendGas")

local function deployGas(pos, toHeal)
	local fxd = EffectData()
		fxd:SetOrigin(pos)
		fxd:SetRadius(el.Radius)
		fxd:SetMagnitude(el.Duration)
	util.Effect("mendgas", fxd)

	sound.Play("arccw_go/smokegrenade/smoke_emit.wav",
		pos + Vector(0, 0, 2), 65, math.random(130, 140), 1)

	table.insert(areas, {toHeal, pos + Vector(0, 0, 2), 0})
end

function Inventory.DeployMendGas(ply, mod)
	local wep = ply:GetActiveWeapon()

	--SuppressHostEvents(ply)

	--SuppressHostEvents(NULL)
	ply:LiveTimer("MendGas_Pull", 0.5, function()
		ply:EmitSound("arccw_go/decoy/pinpull.wav", 50, math.random(90, 110), 0.7)
		ply:ViewPunch(Angle(-2, 0.3, -1))
	end)

	ply:LiveTimer("MendGas_RevPunch", 0.75, function()
		ply:ViewPunch(Angle(1, 1, 1))
		ply:SetViewPunchAngles(Angle(1, -1, 1))
	end)

	local tier = (IsInvModifier(mod) and mod:GetTier()) or (isnumber(mod) and mod)
	if not tier then
		errorNHf("MendGas: second arg not number nor mod (%s: %s)", type(mod), mod)
		tier = 1
	end

	local str = el:GetTierStrength(tier)

	ply:LiveTimer("MendGas_Deploy", 0.8, function()
		local pos = ply:GetPos() + Vector(0, 0, 2)
		local tr = util.TraceHull({
			start = pos + Vector(0, 0, 8),
			endpos = pos - Vector(0, 0, 9999),
			filter = ply,
			mins = Vector(-8, -8, -4),
			maxs = Vector(8, 8, 4),
		})

		local dist = pos:Distance(tr.HitPos)

		pos = tr.HitPos

		if dist > 64 then
			timer.Simple( ((dist - 64) ^ 0.7) / 768, function() deployGas(pos, str) end )
		else
			deployGas(pos, str)
		end
	end)
end

local el = Inventory.Modifiers.Get("MendGas")
	:SetOnActivate(function(base, ply, mod)
		Inventory.DeployMendGas(ply, mod)
		return true
	end)

MendingAffected = MendingAffected or {}
local aff = MendingAffected
local has = not table.IsEmpty(MendingAffected)

timer.Create("MendGasThink", el.TickInterval, 0, function()
	if has then
		for k,v in pairs(aff) do
			if k:IsValid() then
				k:GetPrivateNW():Set("Mending", nil)
			end

			aff[k] = nil
		end

		has = false
	end

	if #areas == 0 then return end

	local ct = CurTime()
	local plys = player.GetConstAll()
	local poses = {}

	for k,v in ipairs(plys) do
		poses[v] = v:GetPos()
	end

	for i=#areas, 1, -1 do
		local dat = areas[i]
		local healTotal, pos, healed = unpack(dat)

		if healed >= healTotal then table.remove(areas, i) continue end

		local toHeal = math.min(
			healTotal / el.Duration * el.TickInterval,
			healTotal - healed
		)

		dat[3] = dat[3] + toHeal

		for k,v in pairs(poses) do
			local vz = v.z
			local pz = pos.z

			if vz + 64 < pz then continue end -- 64u above the gas = cutoff
			if vz - 32 > pz then continue end -- 32u below the gas = cutoff

			v.z = pos.z
			if v:Distance(pos) > el.Radius then continue end
			-- todo: trace?
			k:AddHealth(toHeal)
			aff[k] = true
			has = true
		end
	end

	for k,v in pairs(aff) do
		k:GetPrivateNW():Set("Mending", true)
	end
end)