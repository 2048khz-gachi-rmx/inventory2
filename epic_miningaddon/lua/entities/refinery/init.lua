AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/props/CS_militia/furnace01.mdl"

ENT.MaxQueues = 4
ENT.Refinery = true 


RefineryTbl = RefineryTbl or  {}	--LESS ENT.__index MORE PERFORMANCE 
						
local RefineryTbl = RefineryTbl		--JACKED UP PERFORMANCE, SON

function ENT:Initialize()
	self:SetModel(self.Model)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	self:DrawShadow(false)
	self:SetModelScale(1)
	local phys = self:GetPhysicsObject()

	if (phys:IsValid()) then
		phys:Wake()
		phys:EnableMotion(true)
	end
	RefineryTbl[self] = {}
	local me = RefineryTbl[self]

	me.Queues = {}
	me.MaxQueues = self.MaxQueues
	me.Synced = {}

end

util.AddNetworkString("OreRefinery")

local function CanInteractItem(item)
	if item:GetType()~="ore" or not item:GetAmount() or not item:GetRefined() then return false end
	if item:GetAmount() < (item:GetRefinedRatio()) then print('no!('..item:GetAmount()..'<'..(item:GetRefinedRatio())) return end
	return true
end

function ENT:CanQueue()
	local me = RefineryTbl[self]
	if table.Count(me.Queues) + 1 > me.MaxQueues then return false end
	return true
end

function ENT:SetQueueCap(num)
	RefineryTbl[self].MaxQueues = num 
	local qs = self:GetQueues():sub(1, self:GetMaxQueues())
	qs = qs .. ("2"):rep(num - self:GetMaxQueues())
	self:SetQueues(qs)
	self:SetMaxQueues(num)
end

function ENT:SetQueue(num, val)	-- 0 = busy; 1 = done; 2 = not busy

	local dt = tostring(self:GetQueues())
	dt = dt:SetChar(num, val)
	self:SetQueues(dt)

end

function ENT:QueueProduction(item, ply)

	local me = RefineryTbl[self]
	if not self:CanQueue() then return 'too many queues!' end

	local free = -1 

	for i=1, self:GetMaxQueues() do 
		if not me.Queues[i] then free = i break end
	end

	if free==-1 then print('no free queues!') return end 

	local q = {prod = item:GetRefined(), time = CurTime(), finish = CurTime() + (item:GetItem().ttr or 15), src = item:GetID(), done = false}
	me.Queues[free] = q 
	self:SetQueue(free, 0)

	self:SendInfo(ply)
end

function ENT:Think()
	local me = RefineryTbl[self]

	for k,v in pairs(me.Queues) do 
		if v.done then continue end 

		if CurTime() > v.finish then 
			v.done = true
			self:SetQueue(k, 1)
		end

	end


end

net.Receive("OreRefinery", function(len, ply)
	if not ply:Alive() then return end 
	
	local type = net.ReadUInt(4)

	local ent = net.ReadEntity()

	local uid = net.ReadUInt(32)

	local self = ent --prevent further errors

	local me = RefineryTbl[ent]

	local take = type==1
	local unsub = type==2

	

	if not IsValid(ent) or not ent.Refinery or not me or ply:GetPos():DistToSqr(ent:GetPos()) > 65536 then print('fuk u somethings gone wrong', me, ent) return end 	--65536 = 256^2
	if unsub then me.Synced[ply] = nil return end

	if take then 

		local num = uid --if they want to take, the uid will be the queue number they wanna take
		if not me.Queues[num] or not me.Queues[num].done then print('not done or doesnt exist') return end 

		local q = me.Queues[num]
		local prod = Items[q.prod]
		
		if not prod then print("no product from q", q, q.prod) return end 

		local ret = ply:GiveItem(q.prod, {Amount = prod.res}, nil, ply.Inventory.Temp)

		me.Queues[num] = nil
		ent:SetQueue(num, 2)

		ent:SendInfo(ply)


	else

		local it = ply:HasItem(uid)
		if not it then print(ply,'doesnt have that item',uid) return end 

		
		if not CanInteractItem(it) then print('caninteract didnt like that') return end 

		if not ent:CanQueue() then print('cant q') return end 

		local gotin = ply:TakeItem(uid, (it:GetRefinedRatio()))
		if not gotin then print('not enuff') return end

		local notok = ent:QueueProduction(it, ply)
		if notok then print('refinery err:', notok) end
		ent:SendInfo(ply)
	end

end)

function ENT:SendInfo(ply)

	local me = RefineryTbl[self]

	net.Start("OreRefinery")
		net.WriteEntity(self)
		net.WriteUInt(table.Count(me.Queues), 8)
		for k,v in pairs(me.Queues) do 

			net.WriteUInt(k, 8)
			net.WriteUInt(v.src, 24)
			net.WriteFloat(v.time)

		end

	net.Send(ply)

end

function ENT:Use(ply)

	local me = RefineryTbl[self]
	me.Synced[ply] = true

	self:SendInfo(ply)
	
end