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

local ACTION = {
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

		mod:SetCooldown(nextCd)

		ns:WriteFloat(nextCd)

		return ns
	end,
}

if CLIENT then
	function ACTION.Paint(...)
		local ac = getActiveMod(CachedLocalPlayer())
		if not ac then return end

		ac:GetBase():Paint(...)
	end

	function ACTION.ShouldPaint()
		local ac = getActiveMod(CachedLocalPlayer())
		if not ac then return false end
	end

	local icon = {
		"https://i.imgur.com/6se0gFC.png", "none64_gray.png",
		"https://i.imgur.com/4Fz3Le9.png", "bp_icons/smg_big.png"
	}

	local handle = BSHADOWS.GenerateCache("DarkHUD_OffhandNoActive", 128, 128)

	local mx = Matrix()

	handle:SetGenerator(function(self, w, h)
		surface.SetDrawColor(255, 255, 255, 150)

		local ratio = 176 / 74
		local iw, ih = w, h / ratio

		iw, ih = math.AARectSize(iw, ih, 40)

		-- the p90 can afford to lose the corners in favor of scale
		iw = iw * 1.2
		ih = ih * 1.2

		--[[surface.DrawOutlinedRect(0, 0, w, h)

		mx:Reset()
		mx:TranslateNumber(w / 2, h / 2)
		mx:RotateNumber(0, 40)
		mx:TranslateNumber(-w / 2, -h / 2)

		cam.PushModelMatrix(mx, true)
			surface.DrawOutlinedRect(w / 2 - iw / 2, h / 2 - ih / 2, iw, ih)
		cam.PopModelMatrix()]]

		local a = surface.DrawMaterial(icon[3], icon[4],
			w / 2, h / 2, iw, ih, -40)

		surface.SetDrawColor(255, 255, 255)

		local noSc = 0.7
		local b = surface.DrawMaterial(icon[1], icon[2],
			w * (1 - noSc) / 2, h * (1 - noSc) / 2, w * noSc, h * noSc)

		return a and b
	end)


	local function paintNothing(pnl, x, y, w)
		handle:CacheRet(2, 4, 4)

		local sz = w * 0.65
		local diff = w - sz

		local nx, ny = math.floor(x + diff / 2),
			math.floor(y + diff / 2)

		surface.SetDrawColor(255, 255, 255)
		handle:Paint(x, y, w, w)

		surface.SetDrawColor(Colors.LighterGray:Unpack())
		surface.DrawMaterial(icon[1], icon[2],
			nx, ny, sz, sz)
	end

	function ACTION.PaintNothing(pnl, x, y, w)
		paintNothing(pnl, x, y, w)
	end
end

Offhand.Register("inv_active_mod", ACTION)

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