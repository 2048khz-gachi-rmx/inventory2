include("shared.lua")

local me = {}

function ENT:Initialize()
	
	me[self] = {}
	local me = me[self]

end

function ENT:Draw()
	self:DrawModel()

	local me = me[self]
	if not me then self:Initialize() return end

	local Pos = self:GetPos() + self:GetAngles():Up()
	local Ang = self:GetAngles()

end
