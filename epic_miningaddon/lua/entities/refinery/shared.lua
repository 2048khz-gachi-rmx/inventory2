ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.PrintName = "Refinery or smth"

function ENT:SetupDataTables()

	self:NetworkVar("Bool", 0, "Working")
	self:NetworkVar("String", 0, "Queues")
	self:NetworkVar("Int", 0, "MaxQueues")
	if SERVER then 
		self:SetWorking(false)
		self:SetMaxQueues(4)
		self:SetQueues("2222")
	end

end
