--sasa

local gen = Inventory.GetClass("item_meta", "generic_item")
local bp = Inventory.ItemObjects.Blueprint or gen:Extend("Blueprint")

bp.IsBlueprint = true


function bp:Initialize(uid, iid)


end

function bp:GetResultName()
	local wep = weapons.GetStored(self:GetResult())
	if not wep then return "Invalid weapon" end

	return wep.PrintName
end

function bp:GetName()
	local wep = weapons.GetStored(self:GetResult())
	if not wep then
		return ("T%d %s [%s] Blueprint"):format(self:GetTier(), "Invalid weapon", self:GetResult())
	end

	return ("T%d %s Blueprint"):format(self:GetTier(), wep.PrintName)
end
DataAccessor(bp, "Result", "Result")
DataAccessor(bp, "Modifiers", "Modifiers")
DataAccessor(bp, "Stats", "Stats")
DataAccessor(bp, "Recipe", "Recipe")
DataAccessor(bp, "Tier", "Tier")

bp:Register()


bp:On("GenerateText", "BlueprintModifiers", function(self, cloud, markup)
	self:GenerateText(cloud, markup)
end)

bp:On("PostGenerateText", "BlueprintModifiers", function(self, cloud, markup)
	self:PostGenerateText(cloud, markup)
end)

function bp:PostGenerateText(cloud, markup)
	local has_recipe = not table.IsEmpty(self:GetRecipe())
	if not has_recipe then print("no recipe bruh") return end

	cloud:AddSeparator(nil, cloud.LabelWidth / 8, 8)

	local recipeMup = vgui.Create("MarkupText", cloud)
	recipeMup:SetWide(cloud:GetCurWidth() - 16)

	for id, amt in pairs(self:GetRecipe()) do
		local pc = recipeMup:AddPiece()
		pc:SetAlignment(1)
		local base = Inventory.Util.GetBase(id)
		local col = pc:AddTag(MarkupTag("color", base:GetColor() or Colors.Red))
		pc:AddText(base:GetName())
		pc:EndTag(col)

		pc:AddText(" x" .. amt)
	end

	cloud:AddPanel(recipeMup)
end

function bp:GenerateText(cloud, markup)
	cloud:SetMaxW( math.max(cloud:GetItemFrame():GetWide() * 2.5, cloud:GetMaxW()) )

	for k,v in pairs(self:GetModifiers()) do
		local mod = Inventory.Modifiers.Get(k)
		if mod and mod.Markup then
			mod.Markup (self, markup, v)
		else
			local mpiece = markup:AddPiece()
			mpiece:AddText(k).IgnoreVisibility = true
			mpiece:Debug()
		end
	end
end

function bp:GetWeaponType()
	return Inventory.Blueprints.WeaponPoolReverse[self:GetResult()]
end

local mtrx = Matrix()

local sin = function(d) return math.sin(math.rad(d)) end
local cos = function(d) return math.cos(math.rad(d)) end

function bp:PaintBlueprint(x, y, w, h, fake, col)
	local typ = fake and "random" or self:GetWeaponType()
	local typtbl = Inventory.Blueprints.Types[typ]

	if col ~= false then surface.SetDrawColor(col or color_white) end

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
				local ang = ic.IconAng or 45
				local flip = (ic.Flip == nil and true) or ic.Flip

				local bih = rawIH * math.abs(cos(ang)) + rawIW * math.abs(sin(ang))
				local biw = rawIH * math.abs(sin(ang)) + rawIW * math.abs(cos(ang))

				if url and name then
					local aspectratio = rawIH / rawIW
					local scaleratio = math.min(iw * 0.95 / biw, (ih * 0.96) / bih, 1)

					local resW, resH = rawIW * scaleratio * scale, rawIW * scaleratio * aspectratio * scale

					if flip then
						render.CullMode(1)
							surface.DrawMaterial(url, name, cx, cy, -resW, resH, ang)
						render.CullMode(0)
					else
						surface.DrawMaterial(url, name, cx, cy, resW, resH, ang)
					end
				end
			end
		end)

	render.PopFilterMin()

	if not ok then
		error("Retard: " .. err)
	end
end