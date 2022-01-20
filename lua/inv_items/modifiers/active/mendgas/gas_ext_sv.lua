--

local areas = {}
local el = Inventory.Modifiers.Get("MendGas")

local function deployGas(pos)
	local fxd = EffectData()
		fxd:SetOrigin(pos)
		fxd:SetRadius(el.Radius)
		fxd:SetMagnitude(el.Duration)
	util.Effect("mendgas", fxd)

	sound.Play("physics/glass/glass_impact_bullet" .. math.random(1, 3) .. ".wav",
		pos + Vector(0, 0, 2), 65, math.random(100, 110), 1)

	table.insert(areas, {CurTime(), pos + Vector(0, 0, 2), 0})
end

function Inventory.DeployMendGas(ply)
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
			timer.Simple( ((dist - 64) ^ 0.7) / 768, function() deployGas(pos) end )
		else
			deployGas(pos)
		end
	end)
end

local el = Inventory.Modifiers.Get("MendGas")
	:SetOnActivate(function(base, ply, mod)
		Inventory.DeployMendGas(ply)
		return true
	end)


timer.Create("MendGasThink", el.TickInterval, 0, function()
	if #areas == 0 then return end

	local ct = CurTime()
	local plys = player.GetConstAll()
	local poses = {}

	for k,v in ipairs(plys) do
		poses[v] = v:GetPos()
	end

	for i=#areas, 1, -1 do
		local time, pos, healed = unpack(areas[i])
		if healed >= el.HealTotal then table.remove(areas, i) continue end

		local toHeal = math.min(
			el.HealTotal / el.Duration * el.TickInterval,
			el.HealTotal - healed
		)
		areas[i][3] = areas[i][3] + toHeal
		print("healing:", toHeal, areas[i][3])

		for k,v in pairs(poses) do
			local vz = v.z
			local pz = pos.z

			if vz + 64 < pz then continue end
			if vz - 32 > pz then continue end

			v.z = pos.z
			if v:Distance(pos) > el.Radius then continue end
			-- todo: trace?
			k:AddHealth(toHeal)
		end
	end
end)