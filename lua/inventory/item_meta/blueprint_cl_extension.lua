--
local bp = Inventory.ItemObjects.Blueprint

function bp:GenerateRecipeText(cloud, markup)
	if #cloud:GetPieces() > 0 then
		cloud:AddSeparator(nil, cloud.LabelWidth / 8, 4)
	end

	local recipeMup = vgui.Create("MarkupText", cloud, "Markup - Recipe")
	recipeMup:SetWide(cloud:GetCurWidth() - 16)
	recipeMup.naem = "Markup - Recipe"

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

function bp:PostGenerateText(cloud, markup)
	local has_recipe = not table.IsEmpty(self:GetRecipe())
	if has_recipe then self:GenerateRecipeText(cloud, markup) end
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
