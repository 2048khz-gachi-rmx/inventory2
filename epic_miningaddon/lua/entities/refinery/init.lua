AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/props/CS_militia/furnace01.mdl"


ENT.Refinery = true

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

	if not Inventory.Inventories.Entity then self:Remove() return end --created too early?

	self:SHInit()

	self.Queue = {}
end

util.AddNetworkString("OreRefinery")

function ENT:RemoveOre(slot)
	local it = self.OreInput[slot]
	self.OreInput[slot]:Delete()
end

function ENT:Think()
	local now = false
	local anythingSmelted = false
	local fin_amt = {}

	for k,v in pairs(self.OreInput:GetItems()) do
		local fin = v.StartedRefining + v:GetBase():GetSmeltTime()
		if CurTime() > fin then
			--print(v, "finished")
			local smTo = v:GetBase():GetSmeltsTo()
			if not smTo then print("didn't find what", v:GetName(), " smelts to") continue end --?

			fin_amt[smTo] = (fin_amt[smTo] or 0) + 1
			v:Delete()
			--self.Status:Set(v:GetSlot(), nil)
			anythingSmelted = true
		end
	end

	for name, amt in pairs(fin_amt) do
		local insta = self.OreOutput:NewItem(name, function() self:SendInfo() end, nil, {Amount = amt})
		if insta then now = true end
	end

	if now then self:SendInfo() end
	if anythingSmelted then self.Status:Network() end

	self:NextThink(CurTime() + 0.2)
	return true
end

function ENT:QueueRefine(ply, item, slot)
	if slot > self.OreInput.MaxItems then print("slot higher than max", slot, self.OreInput.MaxItems) return end
	if self.OreInput[slot] then print("there's already an item in that slot") return end

	item:SetAmount(item:GetAmount() - 1)

	self.OreInput:NewItem(item:GetItemID(), function(new)

		self.Status:Set(slot, CurTime())

		timer.Create(("NetworkRefinery:%p"):format(self), 0, 1, function()
			if not IsValid(self) then print(self, "not valid") return end

			local plys = Filter(ents.FindInPVS(self), true):Filter(IsPlayer)
			self.Status:Network()

			Inventory.Networking.NetworkInventory(plys, self.OreInput)
		end)

		new.StartedRefining = CurTime()

	end, slot, item:GetData(), true)
end

-- deposit request
net.Receive("OreRefinery", function(len, ply)
	if not ply:Alive() then return end

	local ent = net.ReadEntity()
	local self = ent

	local slot = net.ReadUInt(16)
	local inv = Inventory.Networking.ReadInventory()
	local item = Inventory.Networking.ReadItem(inv)

	if not inv.IsBackpack then print("inventory is not a backpack") return end
	if not item then print("didn't get item") return end
	ent:QueueRefine(ply, item, slot)

end)

function ENT:SendInfo()
	Inventory.Networking.NetworkInventory(Filter(ents.FindInPVS(self), true):Filter(IsPlayer), self.Inventory, INV_NETWORK_FULLUPDATE)
end

function ENT:Use(ply)
	Inventory.Networking.NetworkInventory(ply, self.Inventory)
	net.Start("OreRefinery")
		net.WriteEntity(self)
		net.WriteUInt(0, 4)
	net.Send(ply)
end