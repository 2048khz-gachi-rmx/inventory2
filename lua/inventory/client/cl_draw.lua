setfenv(1, _G)
Inventory.Draw = Inventory.Draw or {}

local tcol = Color(0, 0, 0)

function Inventory.Draw.DrawItemAmount(id, amt, font, x, y, clr, ax, ay, col2)
	local base = Inventory.Util.GetBase(id)
	local txt1 = "%s"

	if not base then
		txt = "no base (%s) "
		txt = txt:format(id)
	else
		txt = ("%s: "):format(base:GetName())
	end

	local tx2 = ("x%s"):format(amt or "what")
	local axm = (ax or 0) / 2
	local aym = (ay or 0) / 2

	surface.SetFont(font)
	local tw, th = surface.GetTextSize(txt1 .. tx2)
	surface.SetTextPos(x - axm * tw, y - aym * tw)
	surface.SetTextColor(clr:Unpack())

	surface.DrawText(txt)

	tcol:Set( col2 or color_white )
	if not col2 then tcol.a = clr.a end

	surface.SetTextColor( tcol:Unpack() )
	surface.DrawText(tx2)

	return tw, th
end