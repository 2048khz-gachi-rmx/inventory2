local it = Inventory.ItemObjects.Generic

function it:GenerateText(cloud)
	cloud:SetFont("OS24")
	cloud:SetText(self:GetName())

	local lwid = cloud.LabelWidth

	local mup = vgui.Create("MarkupText", cloud)
	mup:SetPaintedManually(true)

	self:Emit("GenerateText", cloud, mup)

	if #mup:GetPieces() < 1 then
		mup:Remove()
	else
		cloud:AddPanel(mup)
		mup:InvalidateLayout(true)
		mup.X = 8
	end

	local len = #cloud.DoneText

	if len > 0 then --some texts were added
		cloud:AddSeparator(nil, lwid / 8, 2, 0)
	end

	cloud:SetColor(Colors.Gray:Copy())
end

it:On("GenerateText", 1, function(self, cloud)
	cloud.MaxW = 250
end)