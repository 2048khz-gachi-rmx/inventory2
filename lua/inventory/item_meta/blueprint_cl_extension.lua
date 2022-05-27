--
local bp = Inventory.ItemObjects.Blueprint

function bp:GetRarityColor()
	return self:GetQuality():GetColor()
end

function bp:GetRarityText()
	local wep = self:GetResult()
	local base = wep and Inventory.Util.GetBase(wep)
	if not base then return "!? 404 base " .. wep end

	local slot = base:GetEquipSlot()

	return ("%s %s BP")
	:format(self:GetQuality():GetName(),
		Inventory.EquippableName(base:GetEquipSlot())
	)
end

local function addItm(pc, iid, amt, space)
	local base = Inventory.Util.GetBase(iid)
	if not base then
		pc:AddText("NO_ITEM: " .. iid .. " x" .. amt .. "  ")
		return
	end

	local nmTxt = pc:AddText(base:GetName())
	local amtTxt = pc:AddText(" x" .. amt .. (space and "  " or ""))

	local haveAmt = Inventory.Util.GetItemCount(Inventory.GetTemporaryInventory(LocalPlayer()), iid)
	amtTxt.color = haveAmt >= amt and color_white or Colors.Red

	local baseCol = (base:GetColor() or Colors.Red):Copy()

	nmTxt.color = baseCol

	return amtTxt
end

function bp:GenerateRecipeText(cloud, markup)
	if #cloud:GetPieces() > 0 then
		cloud:AddSeparator(nil, cloud.LabelWidth / 8, 4)
	end

	local recipeMup = vgui.Create("MarkupText", cloud, "Markup - Recipe")
	recipeMup:SetWide(cloud:GetCurWidth() - 16)
	recipeMup.naem = "Markup - Recipe"

	local skip = false
	local rec = self:GetRecipe()

	for id, amt in pairs(rec) do
		if skip then skip = false continue end

		skip = true
		local pc = recipeMup:AddPiece()
		pc:SetAlignment(1)
		pc:SetFont("BS18")

		local id2, amt2 = next(rec, id)
		addItm(pc, id, amt, id2)

		if not id2 then
			break
		end

		addItm(pc, id2, amt2, false)
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


local bpmat = Material("__error")
draw.GetMaterial("https://i.imgur.com/zhejG17.png", "bp128.png", nil, function(mat)
	bpmat = mat
end)

local caches = {}
local t3c1, t3c2 = Color(4, 12, 8), Color(0.3, 2, 1)
local t4c1, t4c2 = Color(12, 4, 0), Color(12, 4, 0)

Inventory.BlueprintPaints = {

	--[[
		Tier 1 paint
	]]

	[1] = function(self, x, y, w, h)
		surface.SetDrawColor(Colors.DarkWhite)
		surface.DrawMaterial("https://i.imgur.com/zhejG17.png", "bp128.png", x + w * 0.1, y + h * 0.1, w * 0.8, h * 0.8)
	end,

	--[[
		Tier 2 paint
	]]

	[2] = function(self, x, y, w, h)
		x, y = x + math.floor(w * 0.1), y + math.floor(h * 0.1)
		local dw, dh = math.ceil(w - x * 2), math.ceil(h - y * 2)
		local id = 2

		if caches[id] then
			surface.SetDrawColor(255, 255, 255)
			caches[id]:Paint(x, y, dw, dh, true)
			surface.SetMaterial(bpmat)
			surface.DrawTexturedRect(x, y, dw, dh)
		else
			local hand = BSHADOWS.GenerateCache("bp_tier" .. id, w, h)
			hand:SetGenerator(function(hand, w, h)
				surface.SetDrawColor(255, 255, 255)
				surface.SetMaterial(bpmat)
				surface.DrawTexturedRect(0, 0, w, h)
			end)

			caches[id] = hand
			hand:CacheShadow(1, 6, 8, Colors.DarkGray, Colors.DarkGray)
		end
	end,

	--[[
		Tier 3 paint
	]]

	[3] = function(self, x, y, w, h)
		x, y = x + math.floor(w * 0.1), y + math.floor(h * 0.1)
		local dw, dh = math.ceil(w - x * 2), math.ceil(h - y * 2)
		local id = 3

		if caches[id] then
			surface.SetDrawColor(255, 255, 255, 110)
			caches[id]:Paint(x, y, dw, dh, true)
			surface.SetMaterial(bpmat)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawTexturedRect(x, y, dw, dh)
		else
			local hand = BSHADOWS.GenerateCache("bp_tier" .. id, w, h)
			hand:SetGenerator(function(hand, w, h)
				surface.SetDrawColor(255, 255, 255)
				surface.SetMaterial(bpmat)
				surface.DrawTexturedRect(0, 0, w, h)
			end)

			caches[id] = hand
			hand:CacheShadow(3, {14, 8}, 8, t3c1, t3c2)
		end
	end,

	--[[
		Tier 4 paint
	]]

	[4] = function(self, x, y, w, h)
		x, y = x + math.floor(w * 0.1), y + math.floor(h * 0.1)
		local dw, dh = math.ceil(w - x * 2), math.ceil(h - y * 2)
		local id = 4

		if caches[id] then
			surface.SetDrawColor(255, 255, 255)
			caches[id]:Paint(x, y, dw, dh, true)
			surface.SetMaterial(bpmat)
			surface.DrawTexturedRect(x, y, dw, dh)
		else
			local hand = BSHADOWS.GenerateCache("bp_tier" .. id, w, h)
			hand:SetGenerator(function(hand, w, h)
				surface.SetDrawColor(255, 255, 255)
				surface.SetMaterial(bpmat)
				surface.DrawTexturedRect(0, 0, w, h)
			end)

			caches[id] = hand
			hand:CacheShadow(3, {18, 12}, 8, t4c1, t4c2)
		end
	end,

	--[[
		Tier 5 paint (no)
	]]

	[5] = function(self, w, h)
		local x, y = self:LocalToScreen(0, 0)

		BSHADOWS.BeginShadow(x, y, w, h)

			surface.SetDrawColor(color_white)
			surface.SetMaterial(bpmat)
			surface.DrawTexturedRect(w/2 - 40, h/2 - 40, 80, 80)

		BSHADOWS.EndShadow(2, 45, 1, 205, 60, 2, nil, Color(230, 5, 5), Color(170, 1, 1))
	end,
}
