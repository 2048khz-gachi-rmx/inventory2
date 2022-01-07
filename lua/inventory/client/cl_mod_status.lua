--

Inventory.ModPaints = Inventory.ModPaints or {}

local y = 0
function Inventory.StartModPaint(h)
	y = y - h
end

function Inventory.AddModPaint(name, fn)
	Inventory.ModPaints[name] = fn
end

DarkHUD:On("AmmoPainted", "PaintModStatus", function(_, pnl, fw, h)
	y = -8
	for k,v in pairs(Inventory.ModPaints) do
		local add = v(pnl, fw, h, y)
		if isnumber(add) then
			y = y - add
		end
	end
end)