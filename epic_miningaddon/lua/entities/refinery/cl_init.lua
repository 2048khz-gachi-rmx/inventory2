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

function ENT:Initialize()
	me[self] = {}
	local me = me[self]
end

function ENT:DrawDisplay()

	local x, y = -170, 0
	local w, h = 340, 80

	draw.RoundedBox(4, x, y, w, h, Color(40,40,40, 255))
	
	draw.SimpleText("Refinery", "TW72", x+w/2, y+h/2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

end

function ENT:CanInteractItem(item)
	if item:GetType()~="ore" then return false, "Can't refine this item!" end
	local me = me[self]
	local dt = me.DTQ

	local free = select(2, string.gsub(dt, "2", "")) -- 18.04.19: first time i use select!
	if free==0 then return false, "Refinery is full!" end 

	local fromx, tox = item:GetRefinedRatio()
	if fromx > item:GetAmount() then return false, "Too little of this item! (Required at least" .. fromx .. ")" end
	return true
end

function ENT:OnItemHover(item)
	local can, err = self:CanInteractItem(item)
	if not can then return err, false end

	local from = item:GetName()
	local to = Items[item:GetRefined()].name

	local fromx, tox = item:GetRefinedRatio()

	local amt1, name1, amt2, name2 = "", from, "", to
	if fromx>1 then amt1="x"..fromx else amt1=fromx end 
	if tox>1 then amt2="x"..tox else amt2=tox end 

	return string.format("Refine %s %s to %s %s", amt1, name1, amt2, name2)
end

function ENT:OnHover()
	print('hovered')
end

function ENT:InteractItem(item, slot)

	if not self:CanInteractItem(item) then return false end 

	net.Start("OreRefinery")
		net.WriteUInt(0, 4)
		net.WriteEntity(self)
		net.WriteUInt(item:GetUID(), 32)
	net.SendToServer()
	return true
end

function ENT:ContextInteractItem(item, slot)
	
	local ok = self:InteractItem(item)
	if ok==false then return true end

end

function ENT:Draw()
	self:DrawModel()

	local me = me[self]
	if not me then self:Initialize() return end

	local Pos = self:GetPos() + self:GetAngles():Up()*65 + self:GetAngles():Forward() * 16
	local Ang = self:GetAngles()	--idk why i made them uppercase

	Ang:RotateAroundAxis(Ang:Up(),90)
	Ang:RotateAroundAxis(Ang:Forward(),90)

	cam.Start3D2D(Pos, Ang, 0.1)
		pcall(self.DrawDisplay, self)
	cam.End3D2D()

end
function ENT:Think()
	if not me then return end
	local me = me[self]
	if not me then return end
	me.DTQ = self:GetQueues()

end
function ENT:OpenMenu()
	local inv = Inventory.CreateFrame()
	local me = me[self]

	me.InventoryFrame = inv
	inv:SetSize(350, 520)
	inv:SetAlpha(0)
	local fracW = ScrW()/100
	inv:AlphaTo(255, 0.1, 0)
	inv:MakePopup()

	inv:SortItems(function(a,b) 


	local ref = (a:GetRefined() and b:GetRefined())
	local bool = false 

	if not ref then --one of them isnt refineable

		ref = a:GetRefined()
		ref2 = b:GetRefined()
		if not ref then --none are refinable, sort them by amt
			return false
		end 
		return true	--a is refineable and b is not, so put a at the top
	end

	if ref then --both are refineable
		bool = a:GetAmount() > b:GetAmount()
	end

	return bool

	end)-- and (a:GetRefined() and b:GetRefined() and a:GetAmount()>b:GetAmount()) end)
	
	inv:CreateItems()

	local function DehighlightGarbage(v)

		if not v.Item:GetRefined() then 
			v:DeHighlight(true)
		end
		v.DoClick = function()

			local m = vgui.Create("FMenu")
	        m:Open()
	        m:SetAlpha(0)
	        local mx, my = m:GetPos()
	        m:SetPos(mx+1, my)
	        m:MoveTo(mx+7,my, 0.2, 0, 0.4)
	        m:AlphaTo(255, 0.1, 0)
	        local item = v.Item 

	        if item:GetRefined() then 
	            local use = m:AddOption("Queue for refining", function() self:InteractItem(item) end)
	            local ores, to = item:GetRefinedRatio()
	            local str = "Refine x%s %s to x%s %s"
	            str = str:format(ores, item:GetName(), to, item:GetRefinedItem().name)
	            use.Description = str
	            use:SetColor(Color(30, 120, 200))
	            use.Icon = hand
	            use.IconW = 24
	            use.IconH = 24
	        end


		end

	end
	for k,v in pairs(inv:GetItems()) do
		DehighlightGarbage(v)
	end
	function inv:OnNewCell(v)
		DehighlightGarbage(v)
	end

	local drophint = vgui.Create("Cloud")


	local f = vgui.Create("FFrame")
	f:SetSize(600, 520)
	f:Center()
	f:SetPos(ScrW()/2 - 300 - 350/2 - 4, ScrH()/2 - 520/2)

	local dropping = false 

	f:Receiver("ItemDrop", function(me, tbl, drop) 
		print("dropthinking", CurTime())
		dropping = true
		if not drop then 
			drophint:SetAbsPos(gui.MouseX(), gui.MouseY() - 40)	--slot height
			drophint:Popup(true)

			if input.IsShiftDown() then 
				drophint:SetLabel("Queue all")
			else 
				drophint:SetLabel("Queue " .. tbl[1].Item:GetName())
			end 
		else
			drophint:Popup(false)
			self:InteractItem(tbl[1]:GetItem()) 
			dropping = false
		end 
	end)

	function f:Think()
		if not dropping and IsValid(drophint) then 
			drophint:Popup(false)
		else 
			dropping = false 
		end
	end

	me.Frame = f

	inv:SetPos(f:GetPos())
	inv:MoveRightOf(f)

	inv:MoveTo(inv.X + 8, inv.Y, 0.2, 0, 0.4)
	local ent = self 

	function f:OnRemove()
		if IsValid(inv) then 
			inv:Remove()
		end

		if IsValid(drophint) then 
			drophint:Remove()
		end

		net.Start("OreRefinery")
			net.WriteUInt(2,4)	
			net.WriteEntity(ent)
		net.SendToServer()
	end

	local scr = vgui.Create("FScrollPanel", f)
	scr:Dock(FILL)
	scr:DockPadding(16, -8, 16, -8)
	scr:InvalidateParent(true)

	scr.GradBorder = true
	--scr:SetPos(0, f.HeaderSize)

	local qps = {} --queue panels

	local function CreateQueue(k, v)

		local q = vgui.Create("InvisPanel", scr)
		q:SetSize(500, 80)
		q:Dock(TOP)
		q:DockMargin(50, 4, 50, 4)
		q:InvalidateParent()
		qps[k] = q
		local ore
		local bar
		q.QueuedItem = v
		q.Claim = nil 
		local claim

		q.Claim = vgui.Create("FButton", q) 
		claim = q.Claim 	
		claim:SetSize(80, 40)
		claim:SetPos(scr:GetWide() - 100 - 80 - 24, 80/2 - 8)
		claim:SetLabel("Claim")
		claim.DrawShadow = false
		claim.Font = "OS24"
		if claim.Done then claim:SetColor(Color(50,150,250)) else claim:SetColor(Color(40,40,40)) end

		claim.DoClick = function(s)
			if not s.Done or s.Disabled then print("ree") return end
			net.Start("OreRefinery")
				net.WriteUInt(1, 4)
				net.WriteEntity(ent)
				net.WriteUInt(k, 32)
				
			net.SendToServer()
			print("sent")
			s.Disabled = true 
			s:ColorTo(Color(50, 50, 50), 0.3, 0)
		end

		local col = Color(50, 50, 50)
		if me.DTQ[k] == "0" or me.DTQ[k] == "1" then col = Color(70, 70, 70) end 
		if me.DTQ[k] == "2" then claim:SetAlpha(0) end
		function q:Paint(w,h)
			local dt = me.DTQ
			local state = dt[k]

			draw.RoundedBox(4, 0, 0, w, h, col )


			local v = self.QueuedItem
			if v and (state=="0" or state=="1") then 
				ore = Items[v.Ore]
		 		bar = Items[ore.refTo]
				col = LC(col, Color(70, 70, 70))
				local txt = "%s -> %s"
				txt = txt:format(ore.name .. " x" .. ore.reqtr, bar.name .. " x" .. bar.res)

				draw.SimpleText(txt, "TWB32", 16, 4, Color(255,255,255), 0, 5)
				local t = v.Time 
				local ft = ore.ttr
				local time = math.Round((t + ft) - CurTime(),1)
				if time < 0 then time = "Completed!" else time = time .. "s." end

				if claim.Disabled then 
					claim.Disabled = false 
					claim:AlphaTo(255, 0.1)
				end

				if not claim.Done and state == "1" then 
					claim.Done = true 
					claim:ColorTo(Color(50, 150, 250), 0.2)
				end

				draw.SimpleText(time, "TW24", 16, 48, Color(180, 180, 180), 0, 1)
			elseif state=="2" or not v then
				col = LC(col, Color(30, 30, 30))

				if not claim.Disabled then 
					claim.Disabled = true 
					claim:AlphaTo(0, 0.5)
				end

				draw.SimpleText("empty", "TW18", w/2, h/2, Color(255,255,255, 120), 1, 1)
			end

		end
		
		

	end

	for i=1, self:GetMaxQueues() do 
		CreateQueue(i, me.Queue[i])
	end

	function f:Update(tbl)

		for k,v in pairs(qps) do

			v.QueuedItem = me.Queue[k]

		end
		inv:Update(true)
		for k,v in pairs(inv:GetItems()) do
			DehighlightGarbage(v)
		end
	end
	local call = vgui.Create("FButton", f)
	call:Dock(BOTTOM)
	call.Label = "Claim All"
	call:SetSize(400, 80)	
	call:DockMargin(150, 16, 150, 16)
	function call:DoClick()
		for k,v in pairs(qps) do 
			if not v.Claim or not v.Claim.Done or v.Claim.Disabled then continue end 
			net.Start("OreRefinery")
				net.WriteUInt(1, 4)
				net.WriteEntity(ent)
				net.WriteUInt(k, 32)	
			net.SendToServer()
			v.Claim.Disabled = true 
			v.Claim:SetColor(Color(50, 50, 50))
		end
	end
end
net.Receive("OreRefinery", function()
	local ent = net.ReadEntity()
	local amt = net.ReadUInt(8)
	local me = me[ent]
	me.Queue = me.Queue or {}
	for i=1, amt do 
		local num = net.ReadUInt(8)
		local ore = net.ReadUInt(24)
		local time = net.ReadFloat()

		me.Queue[num] = {Ore = ore, Time = time}
	end

	if IsValid(me.Frame) then me.Frame:Update() return end 

	ent:OpenMenu()
end)
