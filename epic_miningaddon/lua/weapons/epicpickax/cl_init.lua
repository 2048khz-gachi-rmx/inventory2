print('ayy')
include("shared.lua")

surface.CreateFont("Pickaxe_Ore", {
        font = "Titillium Web",
        size = 32,
        weight = 400
    })

local function CheckOre()

	local tr = LocalPlayer():GetEyeTrace()

	if not IsValid(tr.Entity) or not tr.Entity.IsOre or tr.Fraction > 256/32768 then 
	return false end --geteyetrace is 32768 units
	return tr.Entity
end


function SWEP:DrawHUD()
	local w,h = ScrW(), ScrH()
	local wep = self
	if not self.Panel then 
		self.Panel = vgui.Create("FFrame")
		local p = self.Panel
		p:SetSize(220, 24)
		p:SetAlpha(0)
		p:Center()
		p:MoveBy(110 + 24, 0, 0)
		p:SetCloseable(false, true)
		p.HeaderSize = 18

		function p:Paint(w,h)
			self:Draw(w,h)
			local i = 0
			if not self.OreInfo then return end
			if LocalPlayer():GetActiveWeapon() ~= wep then self:Remove() return end
			for k,v in pairs(self.OreInfo) do 
				i = i + 1
				local name = "??"
				local col = Color(250, 150, 150)
				if Inventory.Ores[k] then 
					name = Inventory.Ores[k].name
					col = Inventory.Ores[k].col
				end

				surface.SetFont("Pickaxe_Ore")
				surface.SetTextPos(16, -4 + 28 * i)

				surface.SetTextColor(col)
				surface.DrawText(name .. ":")

				surface.SetTextColor(Color(130, 200, 130))
				surface.DrawText(" " .. v.r .. "%")

				--draw.SimpleText(name .. " = " .. v.r, "TW24", 24, 24 * i, color_white, 0, 5)
			end
			local desH = self.HeaderSize + i*28 + 26
			if self:GetTall() ~= desH and not self.Animated then
				self:SizeTo(-1, desH, 0.3, 0, 0.3, function() self.Animated = false end)
				self.Animated = true
			end
			self:CenterVertical()
		end

	end

	local p = self.Panel
	p:SetDraggable(false)
	local ore = CheckOre()

	if not ore then
		p:SetAlpha(L(p:GetAlpha(), 0, 20, true))
		return 
	end

	p:SetAlpha(L(p:GetAlpha(), 253, 20, true))
	p.OreInfo = util.JSONToTable(ore:GetResources()) or p.OreInfo

end

function SWEP:Deploy()
	self.Deployed = true 
	local ind = self:EntIndex()

	hook.Add("InventoryUpdate", "Pickaxe"..ind, function(tbl, diff)
		if not IsValid(self) then hook.Remove("InventoryUpdate", "Pickaxe"..ind) return end 



	end)

end

function SWEP:Holster()
	if IsValid(self.Panel) then 
		self.Panel:Remove()
	end
	self.Panel = nil
end
local g = false

function SWEP:CLPrimaryAttack()

end