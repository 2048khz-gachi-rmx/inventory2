local it = Inventory.ItemObjects.Generic

function it:_CallTextGenerators(cloud)
	cloud:SetFont("EXM28")
	cloud.FontShit = 0.125
	cloud:SetText(self:GetName())
	cloud:SetMaxW(300)
	--cloud.MinW = 250

	local lwid = cloud.LabelWidth

	local mup = vgui.Create("MarkupText", cloud, "Markup - Generic")
	mup:SetPaintedManually(true)
	mup:SetWide(cloud:GetCurWidth() - 16)
	mup.X = 8

	self:Emit("GenerateText", cloud, mup)

	if #mup:GetPieces() > 0 then
		cloud:AddPanel(mup)
	end

	self:Emit("PostGenerateText", cloud, mup)

	if #mup:GetPieces() < 1 then
		mup:Remove()
		--cloud.MinW =  64
	else
		mup:InvalidateLayout(true)
	end

	local len = #cloud.DoneText

	if len > 0 then --some texts were added
		cloud:AddSeparator(nil, lwid / 8, 4, self.AutoSepNum or 0)
	end

	cloud:SetColor(Colors.Gray:Copy())
end

function it:AddChange(k)
	-- of whatever use clientside change tracking might be...
	self.Changes = self.Changes or {}
	self.Changes[k] = true
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

function it:MoveToSlot(slot)
	self:SetSlot(slot)
	self._Commited.Move[self:IncrementToken()] = slot
end

function it:MoveToInventory(inv, slot)
	self._Commited.CrossInv[self:IncrementToken()] = ("%p:%s"):format(inv, slot)
end


function it:PostGenerateText(cloud, markup)

end

function it:GenerateText(cloud, markup)
	return false -- separator required?
end

BaseItemAccessorFn(it, "AmountString", "AmountString")
BaseItemAccessorFn(it, "AmountFormat", "AmountFormat")

it:On("GenerateText", "Base", function(self, cloud, markup)
	self:GenerateText(cloud, markup)
end)

it:On("PostGenerateText", "Base", function(self, cloud, markup)
	self:PostGenerateText(cloud, markup)
end)