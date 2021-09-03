include("shared.lua")

local me = {}

ENT.ContextInteractable = true 


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

local grad
local gradu
local bpbig

local clock

function ENT:Initialize()
	
	me[self] = {}
	local me = me[self]
	bpbig = bpbig or Material("crafting/bp_big.jpg")
	gradu = gradu or Material("gui/gradient_up")
	grad = grad or Material("gui/gradient_down")
	clock = clock or Material("data/hdl/clock.png")

	if bpbig:IsError() then
		hdl.DownloadFile("https://i.imgur.com/IXogD2K.jpg", "crafting/bp_big.jpg", function(fn) bpbig = Material(fn) end)
	end

	if clock:IsError() then 
		hdl.DownloadFile("https://i.imgur.com/NH0gWOj.png", "clock.png", function(f) clock = Material(f) end)
	end

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


local reqs

function CreateCustomizationWindow(gun)
	local f = vgui.Create("FFrame")
	f:SetSize(900, 600)
	f:Center()
	f:SetAlpha(125)
	f:AlphaTo(255,0.05)
	f:SetPos(f.X, f.Y - 16)
	f:MoveTo(f.X,f.Y + 16, 0.15, 0, 0.5)
	f:MakePopup()
	f.Shadow = {}

end


local function ThinkItem(self, w, h)

	if self:IsHovered() then 

	end

end


local function CreateRecipesWindow(tbl, ent)
	if not tbl.cats then print("no dang ole' cats in this table!") return end 

	local rec = vgui.Create("TabbedFrame")
	rec:SetSize(600, 550)

	rec:SetAlpha(0)
	rec:AlphaTo(255,0.2)

	local cx, cy = rec:GetCenter()
	rec:SetPos(cx, cy - 16)
	rec:MoveBy(-1, 16, 0.15, 0, 0.5)

	rec:MakePopup()
	rec.Shadow = {intensity = 3, spread = 1}
	rec:DockPadding(0, 56 + 24, 0, 0)

	rec.Label = "Select a recipe"

	local scr = vgui.Create("FScrollPanel", rec)
	rec:AlignPanel(scr)
	scr:SetSize(scr:GetWide(), scr:GetTall() - 180)
	--scr:Dock(FILL)
	scr.GradBorder = true 
	scr.BorderW = 0
	scr.Expand = true 

	scr.ExpandTH = 0
	scr.ExpandBH = 0

	scr.ExpandW = 0


	local size = 80

	local prio = istable(tbl.catprio) and table.Copy(tbl.catprio)
	local cats = {}

	if prio then 
		for k,v in pairs(prio) do 
			if not tbl.cats[k] then continue end 
			cats[v] = tbl.cats[k]
			cats[v].fancyname = k
		end
	else 
		cats = tbl.cats 

	end

	for k,v in SortedPairs(cats, true) do 
		if not istable(v) then continue end 

		local v = table.Copy(v)
		local name = v.fancyname 

		local items = {}

		rec:AddTab(name or k, function()
			local sX, sY = -size, 8
			local sw = scr:GetWide()

			local pad = 16

			local marg = (sw+pad-scr.VBar:GetWide())%(sX) / 2

			sX = sX + marg + pad

			local selItem = nil 

			for _, it in pairs(v) do 
				if not istable(it) then continue end 

				sX = sX + size + pad

				if sX + size + pad > scr:GetWide() then 
					sX = marg + pad*2
					sY = sY + size + 8
				end
				
				local item = vgui.Create("FButton", scr)
				item:SetAlpha(0)
				item:AlphaTo(255, 0.1, 0)

				item:SetSize(size, size)
				item:SetPos(sX, sY)

				item.DrawShadow = false 
				item.HovMult = 1.4

				item.ItemInfo = it
				item.ID = #items + 1
				function item:PrePaint(w,h)
					if selItem == self then 
						surface.DisableClipping(true)
						draw.RoundedBox(self.RBRadius, -1, -1, w+2, h+2, Color(50, 150, 250))
						surface.DisableClipping(false)
					end
				end
				function item:PostPaint(w,h)
					--surface.DrawMaterial()
					local i = self.ItemInfo.icon 

					if i and i.URL and i.name then 
						local col = i.col or Color(255, 255, 255)
						surface.SetDrawColor(col)
						w2 = i.w or w 
						h2 = i.h or h 

						surface.DrawMaterial(i.URL, i.name, w/2 - w2/2, h/2 - h2/2, w2, h2)
					end

				end
				function item:Think()

					if self:IsHovered() and not self.Description and (not selItem or selItem == self) then 
						local desc = vgui.Create("InvisPanel", rec) 
						desc:PopIn()
						desc:SetSize(scr:GetWide(), 180)
						desc:MoveBelow(scr)
						local curreqs = {}
						local curvar = 0

						if it.vars then 
							desc.Select = vgui.Create("FButton", desc)
							local c = desc.Select
							c.Label = "Select variant"
							c:SetPos(scr:GetWide() - 168, 120)
							c:SetSize(150, 50)

							function c:DoClick()
								local m = vgui.Create("FMenu")
								for k,v in pairs(it.vars) do

									local var = m:AddOption(k, function() 
						            	curreqs = v.reqs
						            end)
						            var.Description = v.desc or "Missing description!"
						            var:SetColor(v.col)
						            var.HovMult = 1.1
						            function var:OnHover()
						            	curreqs = v.reqs
						            end
						            function var:DoClick()
						            	curvar = v.id
						            end
								end
								m:Open()
							end
						elseif it.reqs then
							curreqs = it.reqs
						end

						local allenough = true 

						function desc:Paint(w,h)
							draw.RoundedBoxEx(8, 0, 0, w, h, rec:GetColor(), false, false, true, true)
							draw.SimpleText(it.name, "TW36", w/2, 8, color_white, 1, 5)
							local i = 0
							local all = true

							for id,amt in SortedPairsByValue(curreqs, true) do 
								local item = Items[id]
								if not item then print('no item!!!', id) return end 
								local str = "x%s %s" 
								str = str:format(amt, item.name)

								local has = Inventory.EnoughItem(id, amt)
								if not has then all = false end 

								draw.SimpleText(str, "TW24", 16, 36 + 20*i, (has and Color(100, 200, 100)) or Color(200, 100, 100), 0, 5)
								i = i + 1
							end

							allenough = all 

						end
						local craft = vgui.Create("FButton", desc)
						craft:SetPos(desc:GetWide() / 2 - 70, 120)
						craft:SetSize(140, 40)
						craft:SetColor(60, 60, 60)
						craft:SetAlpha(0)
						craft.Label = "Create!"
						craft.DrawShadow = false
						local active = false 

						function craft:Think()
							local missing = false 

							if table.Count(curreqs) == 0 then 
								self:SetAlpha(L(self:GetAlpha(), 0, 15, true))
								active = false 
								return
							end

							self:SetAlpha(L(self:GetAlpha(), 255, 15, true))

							if allenough and table.Count(curreqs) > 0 then 
								self:SetColor(50, 150, 250)
								craft.DrawShadow = true
								active = true 
							else 
								self:SetColor(60, 60, 60)
								craft.DrawShadow = false
								active = false 
							end
						end

						function craft:DoClick()
							net.Start("Workbench")
								net.WriteUInt(Inventory.StringToID[it.id], 32)
								net.WriteUInt(curvar, 8)
								net.WriteEntity(ent)
							net.SendToServer()
						end

						self.Description = desc 

					elseif not self:IsHovered() and self.Description and (not selItem or selItem ~= self) then 
						self.Description:AlphaTo(0, 0.1, 0, function(_, s) if IsValid(s) then s:Remove() end end)
						self.Description = nil 
					end

				end

				function item:DoClick()
					selItem = ((selItem ~= self) and self) or nil
				end
				items[#items+1] = item
			end

		end, function()

			for k,v in pairs(items) do 

				if IsValid(v) then 
					v:AlphaTo(0, 0.1, 0, function(_,s) 
						if not IsValid(s) then return end 
						s:Remove() 
					end) 
				end

			end

			items = {}

		end)
	end
	--[[
	for k,v in pairs(tbl) do
		if not isnumber(k) then continue end 
		sX = sX + size + pad

		if sX + size + pad > scr:GetWide() then 
			sX = marg + pad*2
			sY = sY + size + 8
		end
		
		local item = vgui.Create("FButton", scr)
		item:SetSize(size, size)
		item:SetPos(sX, sY)
		item.Label = k
		
	end
	]]
	return rec
end

local WorkbenchPanel

function OpenBlueprintCraftingMenu(v, ent)
	local wbp = WorkbenchPanel 
	local inv = WorkbenchPanel.inv 

	local spinner = Material("data/hdl/spinner.png")

	if not IsValid(wbp) or not IsValid(inv) then return end 

	local rec = vgui.Create("TabbedFrame")

	rec:SetPos(wbp.X - 50, wbp.Y - 50)
	local wbw, wbh = WorkbenchPanel:GetSize()

	rec:SetSize(wbw+50, wbh + 100)

	rec:MakePopup()
	rec.Shadow = {intensity = 3, spread = 1}
	rec:DockPadding(0, 56 + 24, 0, 0)

	rec:PopIn()
	wbp.ToRemove[rec] = true 

	function inv:OnNewCell(v)
		if not v.Item.IsBluePrint then 
			v:DeHighlight(true)
		end
	end

	for k,v in pairs(inv.Items) do 
		if v.Item and not v.Item.IsBluePrint then 
			v:DeHighlight(true)
		end
	end

	
	inv:SortItems(function(a, b)
		if a.IsBluePrint and not b.IsBluePrint then return true end
		return false
	end, 1)

	inv:Update(true)
	local anal --xDDDDDDDDDDDDDDDD

	rec:AddTab("Analyze & Craft", function()
		if not IsValid(wbp) then return end
		anal = vgui.Create("InvisPanel", rec)
		anal:PopIn()
		rec:AlignPanel(anal)

		local aw, ah = anal:GetSize()

		local drop = vgui.Create("InvisPanel", anal)
		drop:SetPos(150, 16)
		drop:SetSize(aw - 300, 200)

		local bpw, bph = drop:GetWide() - 64, drop:GetTall() - 24
		local item 

		drop:Receiver("ItemDrop", function(self, tbl, dropped, _, x, y)
			if not dropped then return end 
			local slot = tbl[1]

			item = slot.Item 
			local id = item.ItemID 

			if not item.IsBluePrint then return end 

			self.Blueprint = item 

			self.BlueprintDraw = {x = x - bpw/2, y = y - bph/2, a = 0}

			self.BlueprintLerp = {x = 32, y = 12, a = 255}

			

			if not anal.Analyze then 

				sound.PlayFile("data/hdl/ui/paper_in.dat", "", function() end)

				local b = vgui.Create("FButton", anal)
				anal.Analyze = b 
				b:SetPos(drop.X + drop:GetWide()/2 - 100, drop.Y + drop:GetTall() + 24)
				b:SetSize(200, 70)
				b.Label = "Analyze"
				b:PopIn()
				b:SetColor(Color(40, 140, 230))


				function b:PostPaint(w, h)
					if self.Waiting then 
						
						surface.SetMaterial(spinner)
						surface.SetDrawColor(color_white)
						surface.DrawTexturedRectRotated(w/2, h/2, 64, 64, (CurTime()*-480)%360)
					elseif self.Blueprint.perma.analyzed then 
						self.Label = "Create!"
						self.Color = Color(70, 200, 70, 120)
					else
						self:SetColor(Color(40, 140, 230))
						self.Label = "Analyze"
					end
				end
				local a = 0

				function b:PaintOver(w, h)
					if self.Waiting then 
						a = L(a, 240, 10, true)	
					else 
						a = L(a, 0, 15, true)
					end

					draw.RoundedBox(self.RBRadius, 0, 0, w, h, Color(20, 20, 20, a))
					draw.SimpleText("Analyzing...", "OS24", w/2, h/2, Color(200, 200, 200, a), 1, 1)
				end

				local info = vgui.Create("InvisPanel", anal)

				info:SetPos(0, b.Y + b:GetTall() + 24)
				info:SetSize(aw, anal:GetTall() - info.Y)
				anal.Info = info 
				local als = {}
				local mods = table.Copy(Inventory.Modifiers)

				function info:Paint(w,h)
					draw.RoundedBoxEx(8, 0, 0, w, h, Color(40, 40, 40), false, false, true, true)

					surface.SetMaterial(grad)
					surface.SetDrawColor(Color(20, 20, 20, 200))
					surface.DrawTexturedRect(0, 0, w, 6)


					if self.Name then 
						als.name = L(als.name, 255, 10, true)
						draw.SimpleText(self.Name, "OSB36", w/2, 14, Color(255, 255, 255, als.name), 1, 5)
					end
					if self.Mods then 
						als.mods = L(als.mods, 255, 10, true)
						local i = 0

						for k,v in pairs(self.Mods) do 
							i = i + 1
							local modn = mods[k]
							if not modn then print('unknown mod!', k) continue end
							
							local lv = (isbool(v) and "(unknown)") or v 

							local tw, th = surface.GetTextSize(modn.Name .. " lv." .. lv)
							local sx, sy = self:LocalToScreen(8, 30+30*i)
							local x, y = 8, 30 + 30*i

							--render.SetScissorRect(sx, sy, sx+tw, sy+th, true)
							local text = modn.Name .. " lv." .. lv

							local info = {
								text = text,
								font = "OS24",
							}

								if modn.prepaint then 
									
									local switch = modn.prepaint(x, y, tw, th, lv, self, mods[k], info)
									if switch then 
										x, y = sx, sy 
									end
								end

								
								
								draw.SimpleText(text, "OS24", x, y, modn.col, 0, 5)
								
								if modn.postpaint then 
									
									modn.postpaint(x, y, tw, th, lv, self, mods[k], info)
								end

							--render.SetScissorRect(0, 0, 0, 0, false)
						end

					end

					if self.Stats then 

						local sts = Inventory.Stats
						local i = 0

						for k,v in pairs(self.Stats) do 
							i = i + 1
							local stat = sts[k]
							if not stat then print('unknown stat!', k) continue end
							
							local lv = (v=="?" and "(unknown)") or v 

							if isnumber(lv) then 
	            				local name, col

	            				if not stat.format then 
		            				local val = (stat.diff and stat.diff(v)) or v
		            				if val==0 then continue end
		            				
		            				local good = stat.good and stat.good(val)
		            				local bad = stat.bad and stat.bad(val)

		            				col = (good and Color(100, 200, 100)) or (bad and Color(200, 100, 100)) or Color(150, 150, 150, 100)
		            				
		            				name = string.format(stat.name, (bad and "-") or (good and "+") or "", math.abs(val))
		            			else

		            				name, col = stat.format(v)

		            			end

		            			draw.SimpleText(name or "Wtf", "OS24", aw - 16, 30 + 30*i, col or Color(255, 0, 0), 2, 5)
		            		else

		            			local name

		            			name = string.format(stat.name, "", "???", "", "", "", "") --to be safe

		            			draw.SimpleText(name or "Wtf", "OS24", aw - 16, 30 + 30*i, Color(200, 200, 200), 2, 5)
		            		end
							

						end
					end
					
				end

				info.Mods = item.perma.mods 
				info.Stats = item.perma.stats 

				function b:DoClick()
					if self.Waiting then return end 
					if self.Blueprint.perma.analyzed then 
						net.Start("WorkbenchGun")
							net.WriteUInt(item.ItemUID, 32)
							net.WriteEntity(ent)
						net.SendToServer()
					return end

					item:Analyze(ent)
					self:SetColor(Color(60, 60, 60, 120))
					self.Waiting = true
					self.Label = ""
					Inventory.ItemCallback(item.ItemUID, function(item)
						if not IsValid(b) or not IsValid(info) then return end 
						self.Waiting =false 
						PrintTable(item)
						info.Mods = item.perma.mods
						info.Stats = item.perma.stats 
					end)

					
				end

				anal.Info = info
			else 
				sound.PlayFile("data/hdl/ui/paper_out.dat", "", function() end)
			end


			anal.Analyze.Blueprint = item
			anal.Info.Name = item:GetResultName()
			anal.Info.Mods = item.perma.mods
			anal.Info.Stats = item.perma.stats 
		end)

		local tipa = 255
		local gradcol = Color(0, 0, 0, 200)

		function drop:Paint(w,h)
			draw.RoundedBox(8, 0, 0, w, h, Color(40, 40, 40, self.A))
			
			if self.Blueprint then
				tipa = L(tipa, 0, 50, true)
				gradcol = LC(gradcol, Color(250, 250, 250, 0), 15)
			elseif self.BlueprintHovered then 
				tipa = L(tipa, 0, 50, true)
				gradcol = LC(gradcol, Color(250, 250, 250, 100), 15)

				self.BlueprintHovered = false
			else 
				tipa = L(tipa, 255, 25, true)
				gradcol = LC(gradcol, Color(0, 0, 0, 200), 15)
			end

			draw.SimpleText("Drop your blueprint here", "TW36", w/2, h/2, Color(200, 200, 200, tipa), 1, 1)
			--bpbig is a mat

			if self.Blueprint then 
				local d = self.BlueprintDraw  or {}
				local lt = self.BlueprintLerp or {}
				local bp = self.Blueprint
				for k,v in pairs(lt) do 
					if d[k] then 
						d[k] = L(d[k], v, 10, true)
					end
				end

				surface.SetDrawColor(255,255,255, d.a)
				surface.SetMaterial(bpbig)
				surface.DrawTexturedRect(d.x, d.y, bpw, bph)

				if bp.Overrides and bp.Overrides.icon then 
					local ics = bp.Overrides.icon
					for k,v in pairs(ics) do 
						if k==1 then continue end --the base blueprint icon 

						local url = v.URL 
						local urlname = v.URLName 
						local col = v.Col

						local x, y = d.x + bpw/2, d.y + bph/2 
						local iw, ih = (v.w and v.w*4) or 32*4, (v.h and v.h*4) or 32*4

						x = x - iw/2
						y = y - ih/2

						surface.DrawMaterial(url, urlname, x, y, iw, ih)
					end
				end
			end

			surface.SetDrawColor(gradcol)
			self:DrawGradientBorder(w, h, 4, 4)
		end

		function drop:DragHover(t)

			if dragndrop.m_DraggingMain and dragndrop.m_DraggingMain.Item and dragndrop.m_DraggingMain.Item.IsBluePrint then 
				self.BlueprintHovered = true
			end

		end
	end, function()
		if not IsValid(wbp) then rec:Remove() return end
		anal:PopOut()
	end)

	rec:SelectTab("Analyze & Craft")

	function rec:OnRemove()
		inv:RemoveSort(1)
		inv:Update(true)
		for k,v in pairs(inv.Items) do 
			if v.Item and not v.Item.IsBluePrint then 
				v:DeHighlight(false)
			end
		end
		function inv:OnNewCell(v)

			if not v.Item.IsBluePrint then 
				v:DeHighlight(false)
			end
		end
	end

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
	hdl.DownloadFile("http://vaati.net/Gachi/shared/paper_in.ogg", "ui/paper_in.dat")
	hdl.DownloadFile("http://vaati.net/Gachi/shared/paper_out.ogg", "ui/paper_out.dat")

	local f = vgui.Create("FFrame")
	f:SetSize(600, 520)
	f:Center()
	f:SetPos(ScrW()/2 - 300 - 350/2 - 4, ScrH()/2 - 520/2)
	f:Receiver("ItemDrop", function(me, tbl, drop) if drop then self:InteractItem(tbl[1]:GetItem()) end end)
	f:MakePopup()
	f.Shadow = {}
	f.inv = inv 
	f.ToRemove = {}
	f.ToRemove[inv] = true 

	WorkbenchPanel = f

	me.Frame = f

	inv:SetPos(f:GetPos())
	inv:MoveRightOf(f)

	inv:MoveTo(inv.X + 8, inv.Y, 0.2, 0, 0.4)
	local ent = self 

	function f:OnRemove()
		for k,v in pairs(self.ToRemove) do 
			if IsValid(k) then k:Remove() end
		end
	end
	local i = 0

	for k,v in pairs(Inventory.Crafting) do

		i = i + 1

		local sel = vgui.Create("FButton", f)

		local name = v.singname or "wtf?"
		local label = "Create a%s %s"
		local vow = v.vow 
		if vow==nil then 
			vow = (string.IsVowel(name[1]) and "n") or ""
		else 
			vow = (vow and "n") or ""
		end
		

		label = label:format(vow, v.singname or "[???]")
		sel.Label = label
		sel.Font = "TWB32"
		sel:SetSize(240, 75)
		local off = f.HeaderSize - 75 + 87*i
		sel:SetPos(600/2 - 120, off)

		local rec

		sel.DoClick = function()
			if IsValid(rec) then return end 
			if v.OpenFunc then _G[v.OpenFunc](v, self) return end 

			rec = CreateRecipesWindow(v, self)
		end

	end

end

net.Receive("Workbench", function()
	local ent = net.ReadEntity()

	local me = me[ent]

	if me and IsValid(me.Frame) then me.Frame:Update() return end 

	ent:OpenMenu()
end)
