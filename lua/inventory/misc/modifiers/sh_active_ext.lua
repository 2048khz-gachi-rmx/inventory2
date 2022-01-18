--
Inventory.BaseActiveModifier = Inventory.BaseActiveModifier or Inventory.BaseModifier:callable()

local ac = Inventory.BaseActiveModifier
ac._IsActive = true

ac:SetPowerTier("Active")
ac.ActionName = "inv_active_mod"

function Inventory.BaseModifier:IsActiveModifier()
	return self._IsActive
end

function ac:Initialize(id)
	
end

ChainAccessor(ac, "Icon", "Icon")
ChainAccessor(ac, "IconCopy", "IconCopy") -- intended for drawing

function ac:SetIcon(ic)
	self:SetIconCopy(ic:Copy())
	self.Icon = ic
	return self
end

-- point in curtime after which cooldown is off (ie when putting, set to ct + cooldown)
ChainAccessor(ac, "Cooldown", "Cooldown")

ChainAccessor(ac, "Description", "Description")

function ac:OnActivate() end
ChainAccessor(ac, "OnActivate", "OnActivate")

function ac:CanBind() end
ChainAccessor(ac, "CanBind", "CanBind")

function ac:CanActivate() end
ChainAccessor(ac, "CanActivate", "CanActivate")

function ac:Paint(frame, x, y, size)
	surface.SetDrawColor(20, 20, 20)
	surface.DrawOutlinedRect(x, y, size, size)
	draw.SimpleText("?", "BSSB64", x + size / 2, y + size / 2, color_white, 1, 1)
end
ChainAccessor(ac, "Paint", "Paint")

function ac:CreateOption(mod)
	local opt = Offhand.AddChoice(self.ActionName,
		self:GetName(), self:GetDescription(), self:GetIcon())
end
ChainAccessor(ac, "CreateOption", "CreateOption")

function ac:GetModFromPlayer(ply)
	local wep = ply:GetActiveWeapon()
	if not wep:IsValid() then print("no wep") return false end

	local wd = wep:GetWeaponData()
	if not wd then return end

	return wd:GetMods()[self:GetName()]
end

if CLIENT then
	function ac:RequestAction(mod, ns)
		local pr = Offhand.RequestAction(mod:GetBase().ActionName, ns)
		pr:Then(function()
			local cd = net.ReadFloat()
			mod:SetCooldown(cd)
		end)

		return pr
	end
end


local function getActiveMod(ply)
	local lp = ply or CachedLocalPlayer()
	local wep = lp:GetActiveWeapon()
	if not wep:IsValid() then return end

	local wdt = wep:GetWeaponData()
	if not wdt then return end

	return wdt:GetActiveMod()
end

Offhand.Register("inv_active_mod", {
	Paint = function(...)
		local ac = getActiveMod(CachedLocalPlayer())
		if not ac then return end

		ac:GetBase():Paint(...)
	end,

	ShouldPaint = function()
		local ac = getActiveMod(CachedLocalPlayer())
		if not ac then return false end
	end,

	Use = function(ply)
		local mod = getActiveMod(ply)
		if not mod then return end -- !?

		if mod:GetCooldown() and mod:GetCooldown() > CurTime() then
			return
		end

		mod:SetCooldown(nil)

		local base = mod:GetBase()
		local ns = netstack:new()
		local ok = base:OnActivate(ply, mod)

		if not ok then
			return false
		end

		local nextCd = mod:GetCooldown()

		if not nextCd then
			-- no custom cd set; eval a new one...
			local dur = eval(base:GetCooldown(), base, mod, ply) or 0
			nextCd = CurTime() + dur
		end

		ns:WriteFloat(nextCd)

		return true, ns
	end,
})

local function createEmptyAction(wheel)
	local wep = CachedLocalPlayer():GetActiveWeapon()
	local desc = ("%s\"%s\" has no abilities!")

	if not IsValid(wep) then
		desc = "Well, ya can't have a weapon ability without a weapon now, can you?"
	else
		local name = wep.PrintName or wep:GetClass()
		local your = (wep.ArcCW or wep.CW20Weapon) and "Your " or ""
		desc = desc:format(your, name)
	end

	Offhand.AddChoice(ac.ActionName,
		"Weapon Ability", desc)
end

hook.Add("Offhand_GenerateSelection", "BaseActiveModifier", function(bind, wheel)
	local lp = LocalPlayer()

	local wep = lp:GetActiveWeapon()
	if not wep:IsValid() then createEmptyAction(wheel) return end

	local wdt = wep:GetWeaponData()
	if not wdt then createEmptyAction(wheel) return end

	local have = false

	for name, mod in pairs(wdt:GetMods()) do
		if not mod:GetBase():IsActiveModifier() then continue end

		local base = mod:GetBase()
		if base:CanBind(mod) == false then continue end

		have = true
		base:CreateOption(mod)
	end

	if not have then
		createEmptyAction(wheel)
	end

	--[[for k,v in ipairs(lp:GetWeapons()) do
		local wdt = v:GetWeaponData()
		if not wdt then continue end

		for name, mod in pairs(wdt:GetMods()) do
			if not mod:GetBase():IsActiveModifier() then continue end

			local base = mod:GetBase()
			if base:CanBind(mod) == false then continue end

			base:CreateOption(mod)
		end
	end]]
end)