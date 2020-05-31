include("shared.lua")

local me = {}

function ENT:Initialize()
	me[self] = {}
	local me = me[self]
	me.UsedRN = false 
	me.WasUsed = false
	me.CurBops = 0
	me.LastBops = 0
end

function ENT:Draw()
	self:DrawModel()

	local me = me[self]
	if not me then self:Initialize() return end

	local Pos = self:GetPos() + self:GetAngles():Up()*60
	local Ang = Angle(0, LocalPlayer():EyeAngles().y - 90, 90)
	me.LastBops = me.CurBops
	me.CurBops = self:GetBops()
	if me.LastBops == 4 and me.CurBops == 0 then 
		--self:Bopped()
	end

end
