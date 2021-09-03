local it = Inventory.ItemObjects.Generic

function it:_CallTextGenerators(cloud)
	cloud:SetFont("OS24")
	cloud:SetText(self:GetName())
	cloud:SetMaxW(250)

	local lwid = cloud.LabelWidth

	local mup = vgui.Create("MarkupText", cloud)
	mup:SetPaintedManually(true)
	mup:SetWide(cloud:GetCurWidth() - 16)

	self:Emit("GenerateText", cloud, mup)

	if #mup:GetPieces() < 1 then
		mup:Remove()
	else
		cloud:AddPanel(mup)
		mup:InvalidateLayout(true)
		mup.X = 8

		self:Emit("PostGenerateText", cloud, mup)
	end

	local len = #cloud.DoneText

	if len > 0 then --some texts were added
		cloud:AddSeparator(nil, lwid / 8, 2, 0)
	end

	cloud:SetColor(Colors.Gray:Copy())
end


function it:SetData(k, v)
	if istable(k) then
		for k2,v2 in pairs(k) do
			self.Data[k2] = v2
		end
	elseif not k or not v then
		errorf("it:SetData: expected table as arg #1 or key/value as #2 and #3: got %s, %s instead", type(k), type(v)) 
		return
	end

	self.Data[k] = v
end