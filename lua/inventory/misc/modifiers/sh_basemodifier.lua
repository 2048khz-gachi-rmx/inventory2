
Inventory.BaseModifier = Inventory.BaseModifier or Emitter:callable()
Inventory.Modifiers = Inventory.Modifiers or {}
Inventory.Modifiers.Hooks = Inventory.Modifiers.Hooks or muldim:new()

local mods = Inventory.Modifiers
local hooks = mods.Hooks
local mod = Inventory.BaseModifier

mods.Pool = mods.Pool or {}

ChainAccessor(mod, "MaxTier", "MaxTier")

ChainAccessor(mod, "MinBlueprintTier", "MinBlueprintTier")
ChainAccessor(mod, "MaxBlueprintTier", "MaxBlueprintTier")
ChainAccessor(mod, "MinBlueprintTier", "MinBPTier")
ChainAccessor(mod, "MaxBlueprintTier", "MaxBPTier")

ChainAccessor(mod, "Name", "Name")
ChainAccessor(mod, "Retired", "Retired")
ChainAccessor(mod, "_ModStats", "ModStats")

mod.IsModifier = true

function IsBaseModifier(what)
	return istable(what) and what.IsBaseModifier
end

function mod:SetName(name)
	if self:GetName() then
		mods.Pool[self:GetName()] = nil
	end

	mods.Pool[name] = self
	self.Name = name
	return self
end

function mod:Initialize(name)
	if not name then error("basemodifier requires name bro") return end
	self:SetName(name)

	if SERVER and player.GetCount() > 0 then
		mods.EncodeMods()
		mods.Send(player.GetAll())
	end
end

function mod:GenerateMarkup() end -- for override

function mod:Hook(ev, fn)
	if not hooks:Get(ev) then
		hook.Add(ev, "Inventory_Modifiers", function(...) mods.HookRun(ev, ...) end)
	end

	hooks:Set(fn, ev, self:GetName())

	return self
end

ChainAccessor(mod, "_TierCalc", "TierCalc")
function mod:GetTierStrength(...)
	local fn = self:GetTierCalc()
	if not fn then return -1 end

	return self:GetTierCalc()(self, ...)
end

function mod:_Runner(ev, ...)
	-- get the hook function
	local hkFn = hooks:Get(ev, base:GetName())
	if not hkFn then return end --?

	-- warn about shit performance
	if not self:GetDefaultRunner() then
		errorNHf("Default hook runner for %q - unoptimized as hell!", self:GetName())
	end

	-- find every instance of this modifier
	local inst = mods.InstancePool:Get(base:GetName())
	if not inst then return end

	-- run the hook function on every instance
	for k,v in ipairs(inst) do
		hkFn(inst, ...)
	end
end

ChainAccessor(mod, "_Runner", "Runner")
ChainAccessor(mod, "_DefaultRunner", "DefaultRunner")

mods.IDConv = mods.IDConv or {ToName = {--[[ id = name ]]}, ToID = {--[[ name = id ]]}}

if SERVER then
	util.AddNetworkString("InventoryModifiers")

	function mods.EncodeMods()
		for k,v in pairs(mods.Pool) do
			if mods.IDConv.ToID[k] then continue end
			local max = #mods.IDConv.ToName

			mods.IDConv.ToName[max + 1] = k
			mods.IDConv.ToID[k] = max + 1

			v.ID = max + 1
		end
	end

	function mods.Send(ply)
		net.Start("InventoryModifiers")
			net.WriteUInt(#mods.IDConv.ToName, 16)
			for i=1, #mods.IDConv.ToName do
				net.WriteString(mods.IDConv.ToName[i])
			end
		net.Send(ply)
	end

	hook.Add("PlayerFullyLoaded", "NetworkModIDs", function(ply)
		mods.EncodeMods()
		mods.Send(ply)
	end)

	local know = {}

	hook.Add("InventoryNetwork", "Modifiers", function(ply)
		if know[ply] or not IsPlayer(ply) then return end
		mods.EncodeMods()
		mods.Send(ply)
		know[ply] = true
	end)

	mods.EncodeMods()
	mods.Send(player.GetAll())
else

	net.Receive("InventoryModifiers", function()
		local amt = net.ReadUInt(16)

		for i=1, amt do
			local name = net.ReadString()
			if mods.Pool[name] then
				mods.Pool[name].ID = i

				mods.IDConv.ToID[name] = i
				mods.IDConv.ToName[i] = name
			else
				print("Modifiers: missed mod with name:", name, i)
			end
		end
	end)
end

--[==================================[
				utility
--]==================================]

function mods.IDToName(id)
	return (isstring(id) and mods.IDConv.ToID[id] and id) or mods.IDConv.ToName[id]
end

function mods.NameToID(name)
	return (isnumber(name) and mods.IDConv.ToName[name] and name) or mods.IDConv.ToID[name]
end

mods.ToID = mods.NameToID
mods.ToName = mods.IDToName

function mods.Get(what)
	if IsBaseModifier(what) then return what end

	local nm = mods.IDToName(what) or (isstring(what) and what)
	return mods.Pool[nm]
end

mods.DescColors = {
	Color(100, 250, 100),	-- active tier number
	Color(80, 100, 80),		-- inactive tier number
	Color(130, 130, 130),	-- description
}

include("sh_modifier_ext.lua")