include("shared.lua")

Inventory.DroppedItemPool = Inventory.DroppedItemPool or {}

ENT.GlowRadius = 72 -- only for renderbounds
ENT.BeamHeight = 96

local scale, scaleW = Scaler(1600, 900)

function ENT:FillInventory(ipnl)
	for i=1, 16 do
		local itm = ipnl:Add("ItemFrame")
	end
end

function ENT:QMOnOpen(qm, pnl)
	local sets = Inventory.Panels.PickSettings()
	sets.SlotSize = scaleW(72)

	local inv = Inventory.Panels.CreateInventory(Inventory.Util.GetUsableInventories(LocalPlayer()), nil, sets)

	local invW = (sets.SlotSize + inv.SlotPadding) * sets.FitsItems - inv.SlotPadding
		+ inv:GetRetractedSize() + (8 + 4) * 2


	inv:SetParent(pnl)
	inv:SetFull(true)
	inv:CenterVertical()
	inv:SelectTab("Backpack", true)
	inv:SetDraggable(false)
	inv:SetWide(invW)
	inv:SetCloseable(false, true)

	qm.IFrame = inv

	local f = vgui.Create("FFrame", pnl)
	qm.Frame = f

	f:SetSize(inv:GetSize())
	f:CenterVertical()
	f:PopIn()
	f:SetDraggable(false)
	f.MoveX = -24
	f.WantX = ScrW() * 0.45 - f:GetWide()
	f.X = f.WantX - f.MoveX
	f:SetCloseable(false, true)

	f:MoveBy(f.MoveX, 0, 0.2, 0, 0.3)

	inv.WantX = ScrW() * 0.55
	inv.X = inv.WantX + f.MoveX
	inv:MoveBy(-f.MoveX, 0, 0.2, 0, 0.3)

	local lInvName = vgui.Create("InvisPanel", f)
	lInvName:Dock(TOP)
	lInvName:SetTall(24)

	local lInv = vgui.Create("FIconLayout", f)
	lInv:Dock(FILL)

	f:InvalidateLayout(true)
	self:FillInventory(lInv)
	lInv:UpdateSize(inv:GetSize())

	f:SetTall(lInv.Y + lInv:GetTall() + 8)
	f:CenterVertical()
end

function ENT:QMOnBeginClose(qm, pnl)
	local f, inv = qm.Frame, qm.IFrame
	f:MoveTo(f.WantX - f.MoveX, f.Y, 0.2, 0, 0.3)
	f:PopOutHide()
	inv:MoveTo(inv.WantX + f.MoveX, inv.Y, 0.2, 0, 0.3)
	inv:PopOutHide()
end

function ENT:QMOnReopen(qm, pnl)
	local f, inv = qm.Frame, qm.IFrame
	f:MoveTo(f.WantX, f.Y, 0.2, 0, 0.3)
	f:PopInShow()
	inv:MoveTo(inv.WantX, inv.Y, 0.2, 0, 0.3)
	inv:PopInShow()
end

function ENT:CLInit()
	local qm = self:SetQuickInteractable()

	qm:SetTime(0.35)
	qm.OnOpen = function(_, ent, pnl) self:QMOnOpen(qm, pnl) end
	qm.OnClose = function(_, ent, pnl) self:QMOnBeginClose(qm, pnl) end
	qm.OnReopen = function(_, ent, pnl) self:QMOnReopen(qm, pnl) end
	qm.dist = 96
end

function ENT:Think()

end
