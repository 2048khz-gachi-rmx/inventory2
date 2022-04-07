-- https://i.imgur.com/JoI74AU.png
local el = Inventory.Modifiers.Pool.Marksman

local col = Color(255, 255, 255)
local fullCol = Color(185, 10, 10)
local noCol = Color(150, 150, 150)

Inventory.AddModPaint("Marksman", function(fr, w, h, y)
	local me = CachedLocalPlayer()
	local wep = me:GetActiveWeapon()

	if not wep:IsValid() then return end

	local mod = wep:HasModifier("Marksman")
	if not mod then return end

	local hits = math.max(0, wep:GetNW2Float("MarksmanHits", 0))

	local add, stk = mod:GetTierStrength(mod:GetTier())
	local maxHits = stk / add
	hits = math.min(maxHits, hits)

	local bonus = hits * add

	local font = "EXSB28"

	local tx = ("+%d%%"):format(bonus)
	surface.SetFont(font)
	local tw, th = surface.GetTextSize(tx)

	local sz = 24
	local ix, iy = w - sz - tw - 4, y - sz

	local fr = math.Remap(bonus, 0, stk, 0, 1)
	draw.LerpColor(fr, col, fullCol, noCol)

	DisableClipping(true)
		draw.SimpleText2(tx, font, w, iy + sz / 2, col, 2, 1)
		surface.SetDrawColor(col)
		surface.DrawMaterial("https://i.imgur.com/JoI74AU.png", "mxman.png",
			ix, iy, sz, sz)

	DisableClipping(false)

	return sz
end)