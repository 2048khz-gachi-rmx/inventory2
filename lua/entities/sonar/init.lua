include("shared.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

function ENT:PhysicsCollide(dat, collider)
	if dat.HitEntity ~= game.GetWorld() then return end

	local nang = dat.HitNormal:Angle()
	nang:RotateAroundAxis(nang:Right(), 90)
	self:SetAngles(nang)
	dat.PhysObject:EnableMotion(false)
	--self:SetPos()
end