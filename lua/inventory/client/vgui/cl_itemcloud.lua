local PANEL = {}

function PANEL:Init()
	self.RemoveWhenDone = true
end


function PANEL:SetItemFrame(fr)
	self.Frame = fr
	self:SetItem(fr:GetItem(true))
end

function PANEL:GetItemFrame()
	return self.Frame
end

function PANEL:SetItem(it)
	self.Item = it

	if it then
		it:_CallTextGenerators(self)
	end
end

vgui.Register("ItemCloud", PANEL, "Cloud")