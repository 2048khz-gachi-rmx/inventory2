local PANEL = {}

function PANEL:Init()
	self.RemoveWhenDone = true
end


function PANEL:SetItemFrame(fr)
	self.Frame = fr
	self:SetItem(fr:GetItem(true))
end

function PANEL:SetItem(it)
	self.Item = it

	if it then
		it:GenerateText(self)
	end
end

vgui.Register("ItemCloud", PANEL, "Cloud")