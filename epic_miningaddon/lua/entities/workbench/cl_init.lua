include("shared.lua")


function ENT:Initialize()

end

function ENT:DrawDisplay()

end

function ENT:Draw()
	self:DrawModel()

	local ang = self:GetAngles()
	local up = ang:Up()

	local pos = self:GetPos() + up * 35.4

	ang:RotateAroundAxis(up, -90)

	cam.Start3D2D(pos, ang, 0.075)
		local ok, err = pcall(self.DrawDisplay, self)
		if not ok then print(err) end
	cam.End3D2D()
end

function ENT:CraftThingsMenu(open, main)

	local dicon = vgui.Create("SearchLayout", main)

	main:PositionPanel(dicon)

	local btnSize = 64
	local btnPad = 4

	for i=1, 10 do
		local b = dicon:Add(vgui.Create("FButton"), "test" .. i)
		b:SetSize(btnSize, btnSize)
		b.Label = "test" .. i
	end

	return dicon
end

function ENT:OpenMenu()
	if IsValid(self.Frame) then
		self.Frame:PopInShow()
		self.Frame.Inventory:PopInShow()
		return
	end

	local fits = ScrW() >= 1200 and 6 or 4
	local sz = 	(ScrW() < 1200 and ScrW() > 800 and 80)  or		-- 800 - 1200 = 80x80 (with 4 slots per row)
				(ScrW() >= 1200 and ScrW() < 1900 and 64) or	-- 1200 - 1900 = 64x64 (cause 1200+ fits 6 slots)
				(ScrW() >= 1900 and 80)							-- 1900+ = 80x80 with 6 slots

	local inv = Inventory.Panels.CreateInventory(LocalPlayer().Inventory.Backpack, nil, {
		SlotSize = sz,
		FitsItems = fits,
	})

	--inv:SetTall(350)
	inv:CenterVertical()

	local main = vgui.Create("NavFrame")

	inv:Attach(main, function(inv, main)
		main:MoveLeftOf(inv, 8)
		main.Y = inv.Y
	end)

	main:On("Drag", inv, function(self)
		inv:MoveRightOf(main, 8)
		inv.Y = self.Y
	end)

	self.Frame = main
	main.Inventory = inv
	main:SetCloseable(false, true)
	main.Navbar:Expand()

	inv:SetDeleteOnClose(false)

	function inv:OnClose()
		main:PopOut()
		self:PopOut()
		return false
	end

	main:SetSize(ScrW() < 1200 and 450 or 500, inv:GetTall())
	main:MakePopup()

	main:SetPos( ScrW() / 2 - (main:GetWide() + 8 + inv:GetWide()) / 2,
				ScrH() / 2 - main:GetTall() / 2)
	inv:MoveRightOf(main, 8)

	main.Shadow = {}
	main:SetRetractedSize(40)
	main:SetExpandedSize(230)
	main.BackgroundColor = Color(50, 50, 50)
	inv:Bond(main)
	main:Bond(inv)

	main:PopIn()
	inv:PopIn()

	inv:MoveRightOf(main, 8)

	local mainTab = main:AddTab("Craft garbage", function(_, _, pnl)
		self:CraftThingsMenu(true, main)
	end, function()
		self:CraftThingsMenu(false, main)
	end)

	mainTab:SetTall(60)

	local bpTab = main:AddTab("Craft from blueprint", function(_, _, pnl)
		self:CraftThingsMenu(true, main)
	end, function()
		self:CraftThingsMenu(false, main)
	end)
	--mainTab:Select(true)
end

net.Receive("Workbench", function()
	local ent = net.ReadEntity()

	ent:OpenMenu()
end)
