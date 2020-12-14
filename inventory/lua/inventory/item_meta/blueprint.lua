--sasa

local gen = Inventory.GetClass("item_meta", "generic_item")
local bp = Inventory.ItemObjects.Blueprint or gen:Extend("Blueprint")

bp.IsBlueprint = true


function bp:Initialize(uid, iid)


end

function bp:GetName()
	local wep = weapons.Get(self:GetResult()).PrintName
	return ("T%d %s Blueprint"):format(self:GetTier(), wep)
end
DataAccessor(bp, "Result", "Result")
DataAccessor(bp, "Modifiers", "Modifiers")
DataAccessor(bp, "Stats", "Stats")
DataAccessor(bp, "Recipe", "Recipe")
DataAccessor(bp, "Tier", "Tier")

bp:Register()


bp:On("GenerateText", "BlueprintModifiers", function(self, cloud, markup)
	cloud.MaxW = 250

	for k,v in pairs(self:GetModifiers()) do
		if Inventory.Modifiers.Pool[k].Markup then
			Inventory.Modifiers.Pool[k].Markup (self, cloud, markup)
		else
			local mod = markup:AddPiece()
			mod:AddText(k).IgnoreVisibility = true
		end
	end

end)

function bp:GetWeaponType()
	return Inventory.Blueprints.WeaponPoolReverse[self:GetResult()]
end

local mtrx = Matrix()
local ang = 45

local sin = function(d) return math.sin(math.rad(d)) end
local cos = function(d) return math.cos(math.rad(d)) end

function bp:PaintBlueprint(x, y, w, h)
	local typ = self:GetWeaponType()
	local typtbl = Inventory.Blueprints.Types[typ]

	surface.SetDrawColor(color_white)
	render.PushFilterMin(TEXFILTER.ANISOTROPIC)
		local ok, err = pcall(function()
			local iw = w
			local ih = h
			local bpX, bpY = x, y
			local cx, cy = bpX + iw / 2, bpY + ih / 2

			surface.DrawMaterial("https://i.imgur.com/SpRAhWY.jpg", "crafting/baseblueprint.jpg", bpX, bpY, iw, ih)

			if typtbl and typtbl.BPIcon then
				local ic = typtbl.BPIcon
				local url, name = ic.IconURL, ic.IconName
				local rawIW, rawIH = ic.IconW, ic.IconH
				local scale = ic.IconScale or 1

				local bih = rawIH * math.abs(cos(ang)) + rawIW * math.abs(sin(ang))
				local biw = rawIH * math.abs(sin(ang)) + rawIW * math.abs(cos(ang))

				if url and name then
					local aspectratio = rawIH / rawIW
					local scaleratio = math.min(iw * 0.95 / biw, (ih * 0.96) / bih, 1)

					local resW, resH = rawIW * scaleratio * scale, rawIW * scaleratio * aspectratio * scale
					render.CullMode(1)
						surface.DrawMaterial(url, name, cx, cy, -resW, resH, ang)
					render.CullMode(0)
					--[[mtrx:Translate(Vector(cx, cy))
						mtrx:Rotate(Angle(0, -ang, 0))
					mtrx:Translate(-Vector(cx, cy))

					local bw, bh = iw * 0.95, (ih * 0.96)
					surface.DrawOutlinedRect(cx - bw/2, cy - bh/2, bw, bh)
					cam.PushModelMatrix(mtrx)
						surface.DrawOutlinedRect(cx - resW / 2, cy - resH / 2, resW, resH)
					cam.PopModelMatrix()
					mtrx:Reset()]]
				end
			end
		end)

	render.PopFilterMin()

	if not ok then
		error("Retard: " .. err)
	end
end