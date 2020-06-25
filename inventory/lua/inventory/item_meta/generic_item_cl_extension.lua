local it = Inventory.ItemObjects.Generic

function it:GenerateText(cloud)
	cloud:SetFont("OS24")
	cloud:SetText(self:GetName())

	local lwid = cloud.LabelWidth

	local mup = vgui.Create("MarkupText", cloud)
	mup:SetPaintedManually(true)

	cloud:AddPanel(mup)
	self:Emit("GenerateText", cloud, mup)

	mup:InvalidateLayout(true)
	mup.X = 8
	local len = #cloud.DoneText

	if len > 0 then --some texts were added
		cloud:AddSeparator(nil, lwid / 8, 2, 0)
	end

	cloud:SetColor(Colors.Gray:Copy())
end

it:On("GenerateText", 1, function(self, cloud)
	cloud.MaxW = 250
	cloud:AddFormattedText("this is a generic item's GenerateText & there's nothing special about it")
end)