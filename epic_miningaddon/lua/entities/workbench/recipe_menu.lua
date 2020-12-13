--

function ENT:CraftThingsMenu(open, main)
	if not open then main:HideAutoCanvas("recipe"):SetZPos(999) return end

	local canvas, new = main:ShowAutoCanvas("recipe", nil, 0.1, 0.2)
	canvas:SetZPos(0)
	if not new then return end

	canvas:PopIn(0.1, 0.2)
	main:PositionPanel(canvas)

	local dicon = vgui.Create("SearchLayout", canvas)
	dicon:SetSize(canvas:GetSize())

	local btnSize = 64
	local btnPad = 4

	for i=1, 10 do
		local b = dicon:Add(vgui.Create("FButton"), "test" .. i)
		b:SetSize(btnSize, btnSize)
		b.Label = "test" .. i
	end

	return dicon
end