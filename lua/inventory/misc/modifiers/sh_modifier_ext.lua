Inventory.Modifier = Inventory.Modifier or Emitter:callable()

local mod = Inventory.Modifier
local mods = Inventory.Modifiers
local hooks = mods.Hooks

mod.IsInventoryModifier = true

-- [name] = {inst, inst, ...}
mods.InstancePool = mods.InstancePool or muldim:new()

local function BaseAccessor(tbl, varname, getname)
	tbl["Get" .. getname] = function(self)
		local base = self:GetBase()
		if not base then errorf("Modifier %s didn't have a base!", self:GetName()) return end

		return base[varname]
	end
end

function IsInvModifier(what)
	return istable(what) and what.IsInventoryModifier
end

ChainAccessor(mod, "_Tier", "Tier")

ChainAccessor(mod, "_WD", "WD")
ChainAccessor(mod, "_WD", "WeaponData")

BaseAccessor(mod, "_Name", "Name")
BaseAccessor(mod, "_BaseTier", "BaseTier")
BaseAccessor(mod, "_ModStats", "ModStats")

ChainAccessor(mod, "_Cooldown", "Cooldown")

function mod:GetTierStrength(...)
	return self:GetBase():GetTierStrength(...)
end

function mod:GetBase()
	return mods.Pool[self._BaseName]
end

function mod:Initialize(base)
	local as_str = base

	if isstring(base) then
		base = mods.Pool[base]
	end

	if not base then
		errorf("Failed to find BaseModifier from %q", as_str)
		return
	end

	self._BaseName = base:GetName()
	mods.InstancePool:Insert(self, base:GetName())
end

function mod:Remove()
	mods.InstancePool:RemoveSeqValue(self, self:GetName())
end

--[==================================[
			hooking system
--]==================================]

function mods.HookRun(ev, ...)
	local bases = hooks:Get(ev)
	if not bases then return end

	-- more specialized runner was resolved; bail
	if mods.TryResolveRunner(bases, ev, ...) then
		return
	end

	-- do the default runner which just runs the function
	-- on every instance of the modifier
	for name, fn in pairs(bases) do
		local base = mods.Pool[base]
		if not base then continue end -- e?
		base:GetRunner() (ev, ...)
	end

	--[[
		local inst = mods.InstancePool:Get(base:GetName())
		if not inst then return end

		for k,v in ipairs(inst) do
			hkFn(inst)
		end
	]]
end

include("sh_hook_resolve_ext.lua")