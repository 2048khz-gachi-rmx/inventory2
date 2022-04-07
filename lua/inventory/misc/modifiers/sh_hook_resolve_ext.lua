--

local mods = Inventory.Modifiers
local hooks = mods.Hooks
mods.HookCases = mods.HookCases or {}

local cases = mods.HookCases

local function fromWepOw(ply)
	local wep = ply:GetActiveWeapon()
	if not wep then return end

	local wd = wep:GetWeaponData()
	if not wd then return end

	return wd:GetModifiers()
end

local function modsFromAtkr(dmg)
	local atk = dmg:GetAttacker()
	if not IsPlayer(atk) then return end

	local infl = dmg:GetInflictor()
	local wep = infl:IsWeapon() and infl or atk:GetActiveWeapon()
	if not wep then return end

	local wd = wep:GetWeaponData()
	if not wd then return end

	return wd:GetModifiers()
end

function cases.PostEntityTakeDamage(ev, tgt, dmg)
	return modsFromAtkr(dmg)
end

cases.EntityTakeDamage = cases.PostEntityTakeDamage

function cases.Move(ev, ply, mv)
	return fromWepOw(ply)
end

function cases.SetupMove(ev, ply, mv)
	return fromWepOw(ply)
end

function cases.FinishMove(ev, ply, mv)
	return fromWepOw(ply)
end

function mods.TryResolveRunner(bases, ev, ...)
	if cases[ev] then
		local wdMods = cases[ev] (ev, ...)
		if not wdMods then return false end
		if CLIENT then
			--print("mods", table.Count(wdMods))
		end
		for name, fn in pairs(bases) do
			if wdMods[name] then
				fn(wdMods[name], ...)
			end
		end

		return true
	end

	return false
end

function mods.HasResolvedRunner(ev)
	return not not cases[ev]
end

function mods.ResetHooks()
	for k,v in pairs(mods.Hooks) do
		hook.Remove(k, "Inventory_Modifiers")
		mods.Hooks[k] = nil
	end
end