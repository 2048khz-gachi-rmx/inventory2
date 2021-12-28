--
Inventory.BaseActiveModifier = Inventory.BaseActiveModifier or Inventory.BaseModifier:callable()

local ac = Inventory.BaseActiveModifier
ac._IsActive = true

function Inventory.BaseModifier:IsActiveModifier()
	return self._IsActive
end

function ac:Initialize(id)
	self.OffhandTable = self.OffhandTable or {
		Use = function(ply)
			return self:OnActivate(ply)
		end,

		Paint = function(...)
			self:Paint(...)
		end
	}

	self.ActionName = "actmod_" .. id
	Offhand.Register(self.ActionName, self.OffhandTable)
end

ChainAccessor(ac, "Icon", "Icon")
ChainAccessor(ac, "IconCopy", "IconCopy") -- intended for drawing

function ac:SetIcon(ic)
	self:SetIconCopy(ic:Copy())
	self.Icon = ic
	return self
end

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
	function ac:RequestAction(ns)
		return Offhand.RequestAction(self.ActionName, ns)
	end
end

hook.Add("Offhand_GenerateSelection", "BaseActiveModifier", function(bind, wheel)
	local lp = LocalPlayer()

	for k,v in ipairs(lp:GetWeapons()) do
		local wdt = v:GetWeaponData()
		if not wdt then continue end

		for name, mod in pairs(wdt:GetMods()) do
			if not mod:GetBase():IsActiveModifier() then continue end

			local base = mod:GetBase()
			if base:CanBind(mod) == false then continue end

			base:CreateOption(mod)
		end
	end
end)