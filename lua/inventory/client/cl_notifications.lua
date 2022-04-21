Inventory.Notifications = Inventory.Notifications or {}
local Inv = Inventory
local Not = Inventory.Notifications

Not.NotifyHandlers = Not.NotifyHandlers or {}
Not.MergeHandlers = Not.MergeHandlers or {}

Not.Entries = Not.Entries or {}

local anim = Animatable("InvNotif")

function Not.AddNotifyHandler(typ, fn, mfn)
	Not.NotifyHandlers[typ] = fn
	Not.MergeHandlers[typ] = mfn
end

local namefont = "EXM28"

local function design2(rbRad, x, y, w, h, dat)
	surface.SetMaterial(MoarPanelsMats.gr)
	surface.SetDrawColor(dat.bgcol)
	surface.DrawTexturedRect(x, y + 2, w - 2, h - 4)

	draw.BeginMask()

	draw.Mask()
		draw.RoundedStencilBox(rbRad, x, y, w, h, dat.bgcol)
	draw.DeMask()
		draw.RoundedStencilBox(rbRad, x + 2, y + 2, w - 4, h - 4, dat.bgcol)
	draw.DrawOp()
		surface.SetMaterial(MoarPanelsMats.gr)
		surface.SetDrawColor(dat.hdcol)
		surface.DrawTexturedRect(x + h, y, w, h)

	draw.FinishMask()
end

function Not.DrawNotif(rx, y, h, dat)
	local tw, th = surface.GetTextSizeQuick(dat.name, namefont)

	local a = dat.fr
	dat.maxh = math.max(dat.maxh or 0, h)

	local hder = math.floor(dat.maxh * 0.75)

	local w = math.max(
		192,
		dat.maxh + 4 + tw
		+ 16 + 8
		+ dat.dtpiece:GetWide()
	)

	local x = rx - w

	surface.PushAlphaMult(a)

	local rbRad = 6

	if true then
		design2(rbRad, x, y, w, h, dat)
	else

		draw.RoundedBox(rbRad, x, y, w, h, dat.bgcol)
		draw.RoundedBoxEx(rbRad, x, y, h, h, dat.hdcol, true, false, true, false)

		draw.BeginMask()
		draw.Mask()
			draw.RoundedStencilBox(rbRad, x + hder, y, w - hder, h, dat.bgcol, false, true, false, true)
		draw.DeMask()
			draw.RoundedStencilBox(rbRad, x + hder + 2, y + 2, w - 4 - hder, h - 4, dat.bgcol, false, true, false, true)
		draw.DrawOp()
			surface.SetMaterial(MoarPanelsMats.gl)
			surface.SetDrawColor(dat.hdcol)
			surface.DrawTexturedRect(x + hder, y, w * 1.25, h)
		draw.FinishMask()
	end

	draw.SimpleText2(dat.name, namefont, x + h + 4, y + h / 2 - th / 2 - th * 0.125 / 2, color_white, 0, 0)

	dat.dt:Paint(x + w - 8, y + h / 2 - dat.dt:GetTall() / 2 - th * 0.125 / 2)
	surface.PopAlphaMult()
end


DarkHUD:On("AmmoPainted", "PaintInventoryNotifs", function(_, pnl, fw)
	local h = 32
	local y = DarkHUD.OffhandY

	local rx = fw

	local total_h = 0
	local verPad = 4
	for k,v in ipairs(Not.Entries) do
		total_h = total_h + v.fr * h + verPad
	end

	y = y - math.floor(total_h)

	local sx, sy = pnl:LocalToScreen(0, 0)

	local c = DisableClipping(true)

		for k,v in ipairs(Not.Entries) do
			local fh = math.ceil(v.fr * h)

			render.SetScissorRect(0, sy + y, ScrW(), sy + y + fh, true)
				Not.DrawNotif(rx, y, fh, v)
			render.SetScissorRect(0, 0, 0, 0, false)

			y = y + fh + verPad
		end

	if not c then DisableClipping(false) end
end)

function Not.AddEntry(typ, id, dat)
	local base = Inventory.Util.GetBase(id)
	if not base then
		errorNHf("no base item for ItemID: %s", id)
		return
	end

	dat = dat or {}
	dat.typ = typ
	dat.id = id

	for k,v in ipairs(Not.Entries) do
		if v.typ == typ and v.id == id then
			if Not.MergeHandlers[typ] then
				local bail = Not.MergeHandlers[typ] (v, dat)
				if bail then return false end
			else
				printf("not critical but no notif merger for type %s", typ)
			end
		end
	end

	table.insert(Not.Entries, dat)

	dat.fr = 0
	dat.name = base:GetName()

	local rar = base:GetRarity()
	local rCol = rar and rar:GetColor() or Inventory.Rarities.Default:GetColor()

	dat.bgcol = rCol:Copy():MulHSV(1, 0.8, 0.5)
	dat.hdcol = rCol:Copy():MulHSV(1, 0.7, 0.7)

	local dt = DeltaText()
		:SetFont("EXM24")
		:SetAlignment(2)

	dat.dt = dt

	dat.dtpiece = dt:AddText("")
	dat.dtpiece.Animation.Length = 0

	dt:ActivateElement(dat.dtpiece)

	dat.dtpiece.Animation.Length = 0.3
	anim:MemberLerp(dat, "fr", 1, 0.3, 0, 0.3):Then(function()
		anim:MemberLerp(dat, "fr", 0, 0.2, 5, 2.3):Then(function()
			table.RemoveByValue(Not.Entries, dat)
		end)
	end)

	return dat
end

Not.AddNotifyHandler(INV_NOTIF_PICKEDUP, function(ply)
	local iid = net.ReadUInt(16)
	local amt = net.ReadInt(16)

	local dat = Not.AddEntry(INV_NOTIF_PICKEDUP, iid, {
		amt = amt,
	})

	if dat then
		local k = dat.dtpiece:AddFragment("x" .. math.abs(amt))
		dat.dtfr = k
	end

end, function(old, new)
	old.amt = old.amt + new.amt
	old.dtpiece:ReplaceText(old.dtfr, "x" .. math.abs(old.amt))

	local an = anim:MemberLerp(old, "fr", 1, 0.3, 0, 0.3, true)

	local function die()
		anim:MemberLerp(old, "fr", 0, 0.2, 5, 2.3, true):Then(function()
			table.RemoveByValue(Not.Entries, old)
		end)
	end

	if an then
		an:Then(die)
	else
		die()
	end

	return true
end)

Not.AddNotifyHandler(INV_NOTIF_TAKEN, function(ply)
	local iid = net.ReadUInt(16)
	local amt = net.ReadInt(16)

	Not.AddEntry(INV_NOTIF_TAKEN, iid, {
		amt = amt,
	})
end)

function Not.Recv()
	local typ = net.ReadUInt(8)
	if not Not.NotifyHandlers[typ] then
		errorNHf("no handler for %s", typ)
		return
	end

	Not.NotifyHandlers[typ] ()
end


net.Receive("InvNotify", Not.Recv)