local pos, ang, fov

concommand.Add("inventory_model", function(_, _, _, args)
	print("Args:", args)

	if not args or #args < 3 or not args:match("models/.+") then
		print("Invalid argument, expected a model name. You sure you know what you're doing?...")
		return
	end

	if IsValid(AdjF) then
	    pos, ang, fov = AdjF.Adj:GetCamPos(), AdjF.Adj:GetLookAng(), AdjF.Adj:GetFOV()
	    AdjF:Remove()
	end

	local mdl = args
	local f = vgui.Create("DFrame")
	AdjF = f
	f:SetSize(500, 500)
	f:Center()
	f:MakePopup()

	local adj = f:Add("DAdjustableModelPanel")
	adj:Dock(FILL)
	adj:SetModel(mdl)
	adj.LayoutEntity = BlankFunc
	f.Adj = adj

	if pos then
	    adj:SetCamPos(pos)
	    adj:SetLookAng(ang)
	    adj:SetFOV(fov)
	end
	function adj:PaintOver(w, h)
	    draw.SimpleText("CamPos " .. tostring(self:GetCamPos()), "OS24", 0, h - 72, color_white, 0, 5)
	    draw.SimpleText("Angle " .. tostring(self:GetLookAng()), "OS24", 0, h - 48, color_white, 0, 5)
	    draw.SimpleText("FOV " .. tostring(self:GetFOV()), "OS24", 0, h - 24, color_white, 0, 5)
	end


	local btn = f:Add("DButton")
	btn:SetPos(f:GetWide()/2 - 60, 36)
	btn:SetSize(120, 36)
	btn:SetText("Copy")

	local tx = [[	:SetCamPos( Vector(%.1f, %.1f, %.1f) )
	:SetLookAng( Angle(%.1f, %.1f, %.1f) )
	:SetFOV( %.1f )]]
	function btn:DoClick()
	    local pos, ang, fov = adj:GetCamPos(), adj:GetLookAng(), adj:GetFOV()
	    SetClipboardText(tx:format(pos[1], pos[2], pos[3], ang[1], ang[2], ang[3], fov))
	end
end)