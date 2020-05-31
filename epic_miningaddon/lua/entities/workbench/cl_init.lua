include("shared.lua")

local me = {}

ENT.ContextInteractable = true 

local function LC(col, dest, vel)
    local v = 10
    if not IsColor(col) or not IsColor(dest) then return end
    if isnumber(vel) then v = vel end
    local r = Lerp(FrameTime()*v, col.r, dest.r)
    local g = Lerp(FrameTime()*v, col.g, dest.g)
    local b = Lerp(FrameTime()*v, col.b, dest.b)
    return Color(r,g,b)
end

local function L(s,d,v,pnl)
    if not v then v = 5 end
    if not s then s = 0 end
    local res = Lerp(FrameTime()*v, s, d)
    if pnl then 
        local choose = res>s and "ceil" or "floor"
        res = math[choose](res) 
    end
    return res
end


function ENT:CanInteractItem(item)

	return true
end

function ENT:OnItemHover(item)
	

end

function ENT:OnHover()
	print('hovered')
end

function ENT:OnUnhover()
	print('unhov')
end

function ENT:InteractItem(item, slot)

	return true
end

--[[
function ENT:ContextInteractItem(item, slot)
	
	local ok = self:InteractItem(item)
	if ok==false then return true end

end
]]

function ENT:Initialize()
	
	me[self] = {}
	local me = me[self]

end

function ENT:DrawDisplay()

	draw.RoundedBox(16,-500, -210, 1000, 420, Color(50, 50, 50, 200))
	draw.SimpleText("Workbench", "RL72", 0, -160, Color(255,255,255), 1, 1)
	draw.SimpleText("No production queued!", "TW72", 0, 0, Color(255,255,255, 100), 1, 1)
end

function ENT:Draw()
	self:DrawModel()

	local me = me[self]
	if not me then self:Initialize() return end

	local pos = self:GetPos() + self:GetAngles():Up()*35.4
	local ang = self:GetAngles()
	ang:RotateAroundAxis(ang:Up(), -90)

	cam.Start3D2D(pos,ang, 0.075)
		local ok, err = pcall(self.DrawDisplay, self)
		if not ok then print(err) end
	cam.End3D2D()
end
local grad = Material("gui/gradient_down")
local gradu = Material("gui/gradient_up")

local clock = Material("data/hdl/clock.png")
hdl.DownloadFile("https://i.imgur.com/NH0gWOj.png", "clock.png", function(f) clock = Material(f) end, nil, true)

local reqs

function CreateCustomizationWindow(gun) --good god im lost in these vars&tables!
	local f = vgui.Create("FFrame")
	f:SetSize(900, 600)
	f:Center()
	f:SetAlpha(125)
	f:AlphaTo(255,0.05)
	f:SetPos(f.X, f.Y - 16)
	f:MoveTo(f.X,f.Y + 16, 0.15, 0, 0.5)
	f:MakePopup()
	f.Shadow = {}

	local req = {}	--required resources - total

	local attbtns = {} --attachment buttons

	local attsel	--selected attachment(the frame that slides out)

	local attreqs = {} --requirement per each attachment : {["barrel"] = {[1101] = 75, ...}, ...}

	
	local function UpdateReqs()	--requirements for all attachment (text on the right)

		req = {}

		for _,btn in pairs(attbtns) do 
			for id, amt in pairs(btn.Resources) do
					req[id] = (req[id] or 0) + amt
			end 
		end


	end
	
		local function UpdateAttReqs()	--requirements for 1 attachment only (text in the cloud)
			
		--[[
			for name, btn in pairs(attbtns) do 
				attreqs[name] = {}
				for id,amt in pairs(btn.sel.mats) do
					attreqs[name][id] = (attreqs[name][id] or 0) + amt
				end

				table.Empty(btn.Cloud.DoneText)

				for id,amt in pairs(attreqs[name]) do

					local txt = "x%s %s"
					txt = txt:format(amt, Items[id].name)

					local has = Inventory.EnoughItem(id, amt, taken[id])

					if has then taken[id] = (taken[id] or 0) + amt end

					btn.Cloud:AddFormattedText(txt, (has and Color(100, 200, 100)) or  Color(200, 100, 100))

				end

			end

			UpdateReqs()
			]]
		end
	
	for name,v in pairs(gun.att) do 
		attbtns[name] = vgui.Create("FButton", f)
		local b = attbtns[name]
		b:SetSize(48, 48)
		b:SetPos(v.x, v.y)
		b:SetText("")
		b.Buttons = {}

		b.AttName = name 
		b.AttTbl = v

		local ic = v.icon
		 

		local cl = vgui.Create("Cloud", b)
		cl:Popup(false)
		cl.YAlign = 0
		cl.Middle = 0.8
		cl:SetAbsPos(0, 48)
		b.Cloud = cl 

		local lasthov = 0
		local attn

		b.sel = v.types[1]
		local sel = b.sel
		b.IconColor = sel.col
		b.Resources = {}

		for k,v in pairs(sel.mats) do 
			b.Resources[k] = (b.Resources[k] or 0) + v
		end

		function b:Paint(w,h)
			self:Draw(w,h)

			if ic then 
				surface.SetDrawColor(self.IconColor or Color(255, 0, 255))
				surface.SetMaterial(ic)
				surface.DrawTexturedRect(v.ix or 0, v.iy or 0, v.iw or 48, v.ih or 48)
			end

			local hov = self:IsHovered() 
			local mehov = hov

			local attn = self.sel.name --base name of currently selected

			if not hov then 

				for k,btn in pairs(self.Buttons) do 
					if not IsValid(btn) then continue end 

					hov = btn:IsHovered()

					if hov then 

						attn = btn.SubAtt.name --name of material
						
						local lab = v.name
				
						lab = lab:format(attn or "Scrap")

						cl.Label = lab
					
						cl.DoneText = {}

						for id, amt in pairs(btn.Resources) do 
							local name = Items[id].name 

							local str = "x%s %s"
							str = str:format(amt, name)

							cl:AddFormattedText(str, Color(200, 200, 200, 150))
						end

					break end 

				end 

			end

			if hov then 
				lasthov = CurTime()
			end
			hov = hov or CurTime()-lasthov < 0.3
			cl:Popup(hov)
			
			if hov then 
				cl:SetAbsPos(w/2 - 4, L(cl.YShit, -16, 15, true))
				
			else 
				cl:SetAbsPos(w/2 - 4, L(cl.YShit, 0, 15))
			end

			if mehov then --the selected attachment was hovered: use its' info

				local lab = v.name
				
				lab = lab:format(attn or "Scrap")

				cl.Label = lab
			
				cl.DoneText = {}
				for id, amt in pairs(self.Resources) do 
					local name = Items[id].name 
					local str = "x%s %s"
					str = str:format(amt, name)

					cl:AddFormattedText(str, Color(200, 200, 200, 150))
				end

			end

		end
		
		
		function b:DoClick()
			if IsValid(attsel) and attsel.Attachment==self then return
			elseif IsValid(attsel) then 
				attsel:AlphaTo(0,0.05)
				attsel:MoveTo(attsel.X-12,attsel.Y,0.1, 0, 0.6, function(t,s) s:Remove() end) 
			end 
			local s = vgui.Create("InvisPanel", f)
			local w, h = 48, 52 * #v.types
			s:SetSize(w, h)
			local px, py = self:GetPos()

			s:SetPos(px + 48 - 8, py + 24 - h/2)
			s:SetAlpha(0)
			s:AlphaTo(255,0.1)
			s:MoveTo(s.X+12,s.Y,0.2, 0, 0.6)
			s.Attachment = self
			for k,v in pairs(v.types) do 
				local ch = vgui.Create("FButton", s)
				ch:SetSize(48, 48)
				ch:SetPos(0, -48 + 50*k)
				ch:SetColor(v.col)
				ch.SubAtt = v
				ch.Resources = {}
				for k,v in pairs(v.mats) do 
					ch.Resources[k] = (ch.Resources[k] or 0) + v
				end
				ch.DoClick = function(self)
					if s.Disabled then return end 

					s:AlphaTo(0,0.1, 0.06)
					s:MoveTo(s.X-12,s.Y,0.12, 0.06, 0.6, function() s:Remove() end)
					s.Disabled = true
					self:SetParent(f)
					self:SetPos( f:ScreenToLocal(s:LocalToScreen(self.X, self.Y) ) )

					self:MoveTo(b.X, b.Y, 0.2, 0, 0.4, function() 
						b.sel = v 
						b.IconColor = v.col 
						UpdateAttReqs() 
						table.Empty(b.Resources)
						for k,v in pairs(v.mats) do 
							b.Resources[k] = (b.Resources[k] or 0) + v
						end
						UpdateReqs()
					end) 
					self:AlphaTo(0, 0.1, 0.2, function()  self:Remove() end)

				end

				self.Buttons[k] = ch
			end
			attsel = s
		end

	end


	function f:Paint(w,h)
		self:Draw(w,h)
		surface.SetDrawColor(40, 40, 40)
		surface.DrawLine(650, self.HeaderSize, 650, h)
		draw.SimpleText("Requirements:","TW32", 650 + 8, self.HeaderSize + 4, color_white, 0, 5)

		local i = 0

		for k,v in pairs(req) do 
			i = i + 1
			local str = "♂ x%s %s"
			local it = Items[k]
			local name = (it and it.name) or "INVALID ITEM"

			str = str:format(v, name)
			local col = Color(200, 100, 100)
			if Inventory.EnoughItem(k, v) then col = Color(100, 200, 100) end
				
			draw.SimpleText(str, "TW24", 650 + 32, self.HeaderSize + 4 + 8 + 24*i, col, 0, 5)
		end
		UpdateReqs()
	end
	local mdl = vgui.Create("DModelPanel", f)
	mdl:SetSize(650, 600 - f.HeaderSize)
	mdl:SetModel(gun.mdl)
	mdl:SetPos(0, f.HeaderSize)
	mdl.LayoutEntity = function() end
	local pnt = mdl.Paint 
	function mdl:Paint(w,h)
		surface.SetDrawColor(30, 30, 30)
		surface.DrawRect(0, 0, w, h)
		pnt(self,w,h)
	end

	for k,v in pairs(attbtns) do 
		v:MoveToFront()
	end
	--pepehands for 3d buttons :(
	local camdat = gun.camdata 

    mdl:SetFOV( camdat.fov or 60 )
    mdl:SetCamPos( camdat.pos or Vector(0,0,0) )
    mdl:SetLookAt( camdat.look or Vector(0,0,0) )
    UpdateReqs()
end

local function CreateRecipesWindow()
	local rec = vgui.Create("FFrame")
	rec:SetSize(600, 800)
	rec:Center()
	rec:SetAlpha(0)
	rec:AlphaTo(255,0.2)
	rec:SetPos(rec.X, rec.Y - 16)
	rec:MoveTo(rec.X,rec.Y + 16, 0.15, 0, 0.5)
	rec:MakePopup()
	rec.Shadow = {}

	function rec:Paint(w,h)
		self:DrawHeaderPanel(w,h)

		draw.SimpleText("Select Recipe","TW48", w/2, 56, color_white, 1, 1)
	end


	rec.Scroll = vgui.Create("FScrollPanel", rec)
	local scr = rec.Scroll 
	scr:SetSize(600, 700)
	scr:SetPos(0, 100)
	scr.BackgroundColor = Color(0,0,0,0)

	local topper = vgui.Create("InvisPanel", rec)
	topper:MoveToAfter(scr)
	topper:SetSize(1,1)

	local ps = {}
	local i = 0

	for k,v in pairs(Inventory.Crafting.guns) do 
		i = i + 1
		local ip = scr:Add("InvisPanel")
		ip:SetSize(520, 100)
		ip:Dock(TOP)
		ip:DockMargin( 20, 24, 20, 8 )

		local exd = false
		local iW, iH = 560, 100
		local desc = string.WordWrap(v.desc or "", 520, "TW24")
		local _, ns = string.gsub(desc, "\n", "")
		local th = 24 + 24*ns
		
		local fH = 100

		if th+32+16>100 then 
			ip:SetSize(520, th+16+32)
			fH = th+16+32
		end

		local max = fH+120 --when expanded

		local att = {}

		if not v.att then print('wtf') return end 


		for attid, tbl in pairs(v.att) do 

			att[attid] = {}
			local atdata = att[attid]

			for k,v in pairs(tbl.types) do

				local req = {} 
				for id, amt in pairs(v.mats) do 
					req[id] = (req[id] or 0) + amt
				end


				atdata[k] = {name = tbl.name:format(v.name), req = req}
			end


			

		end
		PrintTable(att)

		local function DrawReqs(req, w)
			draw.SimpleText("Requirements:", "TW24", w/2 - 4, fH + 32, color_white, 2, 1)
			local i = 0

			for k,v in pairs(req) do 
				i = i + 1
				local str = "x%s %s"
				local it = Items[k]
				local name = (it and it.name) or "INVALID ITEM"

				str = str:format(v, name)
				local col = Color(200, 100, 100)
				if Inventory.EnoughItem(k, v) then col = Color(100, 200, 100) end
					
				draw.SimpleText(str, "TW18", w/2 + 4, fH + 9 + 16*i, col, 0, 5)
			end
		end

		local selchance

		if chances then 
			local ch = vgui.Create("FButton", ip)
			ch:SetSize(32, 32)
			ch:SetPos(4, 36 )

			function ch:Paint(w,h)
				local x, y = self:LocalToScreen(0,0)
				BSHADOWS.BeginShadow()
					surface.SetDrawColor(255, 255, 255)
					surface.SetMaterial(clock)
					surface.DrawTexturedRect(x, y, w, h)
				BSHADOWS.EndShadow(2, 1, 0, 255)

			end

		end

		function ip:Paint(w,h)
			iW, iH = w, h
			draw.RoundedBoxEx(4, 0, 0, 560, fH, Color(60, 60, 60), true, true)

			if exd then 
				self:SetSize(w, L(h, max, 15, true))
			else 
				self:SetSize(w, L(h, fH, 15, true))
			end

			draw.SimpleText(v.name, "TWB32", w/2, 2, color_white, 1, 5)
			draw.DrawText(desc, "TW24", 4, 32, color_white, 0)

			local dh = h-fH
			if dh<=0 then return end 

			draw.RoundedBoxEx(4, 0, fH, 560, fH, Color(45, 45, 45), false, false, true, true)

			surface.SetDrawColor(30, 30, 30, 200)
			surface.SetMaterial(grad)
			surface.DrawTexturedRect(0, fH, w,  32)

			if v.time then 
				surface.SetDrawColor(235, 235, 235)
				surface.SetMaterial(clock)
				surface.DrawTexturedRect(8, fH+16, 32, 32)
				local t = string.FormattedTime(v.time)

				local str = "%s%s:%s"
				local h = (t.h~=0 and (t.h .. ":")) or ""

				local m = (t.m~=0 and t.m) or "00"
				if m<10 then m="0"..m end 

				local s = (t.s~=0 and t.s) or "00"
				if s<10 then s="0"..s end 


				str = str:format(h,m,s)
				draw.SimpleText(str, "TW24", 16+32, fH + 32, color_white, 0, 1)

			end
			if table.Count(att)==0 then return end 
			--[[
			for name,v in pairs(att) do 
				for id, info in pairs(v) do
					DrawReqs(info.req, w)
				end

			end]]

		end

		local cust = vgui.Create("FButton", ip)
		cust.Label = "Customize"
		cust.Font = "TW24"
		cust:SetSize(160, 30)
		cust:SetPos(iW/2 - 80, max - 40)
		cust:SetColor(50, 150, 250)

		cust.DoClick = function()
			if IsValid(ip.Customization) then return end
			ip.Customization = CreateCustomizationWindow(v)

		end


		local exp = vgui.Create("DButton", scr)
		exp:SetSize(120, 20)
		exp:SetPos(ip.X/2+30, ip.Y + math.max(100, th+8+32) + 20)
		exp:SetText("")
		exp:MoveToAfter(ip)

		
		function exp:Paint(w,h)

			self:SetPos(ip.X + 560/2 - 60, ip.Y + iH )
			draw.RoundedBoxEx(8, 0, 0, w, h, Color(40, 40, 40), false, false, true, true)
			draw.SimpleText((not exd and "V") or "^","TW24",w/2,h/2,color_white,1,1)

		end


		exp.DoClick = function(s)
			exd = not exd
		end



		ps[i] = ip 

	end

	local botter = vgui.Create("InvisPanel", scr)
	local sw, sh = scr:GetSize()
	botter:SetPos(0, 88*i)
	botter:SetSize(1,1)
	return rec
end

function ENT:OpenMenu()
	local inv = Inventory.CreateFrame()
	local me = me[self]

	me.InventoryFrame = inv
	inv:SetSize(350, 520)
	inv:SetAlpha(0)
	local fracW = ScrW()/100
	inv:AlphaTo(255, 0.1, 0)
	
	inv:CreateItems()

	local f = vgui.Create("FFrame")
	f:SetSize(600, 520)
	f:Center()
	f:SetPos(ScrW()/2 - 300 - 350/2 - 4, ScrH()/2 - 520/2)
	f:Receiver("ItemDrop", function(me, tbl, drop) if drop then self:InteractItem(tbl[1]:GetItem()) end end)
	f:MakePopup()

	me.Frame = f

	inv:SetPos(f:GetPos())
	inv:MoveRightOf(f)

	inv:MoveTo(inv.X + 8, inv.Y, 0.2, 0, 0.4)
	local ent = self 

	function f:OnRemove()
		if IsValid(inv) then 
			inv:Remove()
		end
	end


	function f:Update(tbl)

	end

	local sel = vgui.Create("FButton", f)
	sel.Label = "Select Recipe"
	sel.Font = "TW24"
	sel:SetSize(120, 40)
	sel:SetPos(600/2-60, 520 - 50)

	local rec

	sel.DoClick = function()
		if IsValid(rec) then return end 
		rec = CreateRecipesWindow()
	end
	
end

net.Receive("Workbench", function()
	local ent = net.ReadEntity()

	local me = me[ent]

	if IsValid(me.Frame) then me.Frame:Update() return end 

	ent:OpenMenu()
end)
