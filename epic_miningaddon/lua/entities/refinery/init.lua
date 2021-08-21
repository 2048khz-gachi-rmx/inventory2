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

	local prs = {}

	for name, amt in pairs(fin_amt) do
		local pr = self.OreOutput:NewItem(name, function() self:SendInfo() end, nil, {Amount = amt})
		if pr then
			table.insert(prs, pr)
		end
	end

	Promise.OnAll(prs, function()
		if IsValid(self) then self:SendInfo() end
	end)

	if anythingSmelted then self.Status:Network() end

	self:NextThink(CurTime() + 0.2)
	return true
end

function ENT:AddInputItem(inv, item, slot)
	local meta = Inventory.Util.GetMeta(item:GetItemID())
	local new = meta:new(nil, item:GetItemID())
	--new:SetSlot(slot)
	new:SetAmount(1)
	new:SetOwner(inv:GetOwner())
	new.StartedRefining = CurTime()
	new.AllowedRefineryInsert = true

	return self.OreInput:InsertItem(new, slot)
end

function ENT:QueueRefine(ply, inv, item, slot, bulk)
	if bulk then
		local prs = {}
		local amt = item:GetAmount()
		local ins = 0

		for i=1, self.OreInput.MaxItems do
			if self.OreInput.Slots[i] then print("nope") continue end
			if ins >= amt or not item:IsValid() then print("Item invalid") break end

			local ok, pr = xpcall(self.AddInputItem, GenerateErrorer("Refinery"),
				self, inv, item, i)
			if not ok then print("couldn't add input item to #" .. i) continue end

			prs[#prs + 1] = pr

			ins = ins + 1
			pr:Then(function()
				self.Status:Set(i, CurTime())
			end)

			item:SetAmount(item:GetAmount() - 1)
		end

		Promise.OnAll(prs):Then(function()
			if not IsValid(self) then return end

			local plys = Filter(ents.FindInPVS(self), true):Filter(IsPlayer)
			Inventory.Networking.NetworkInventory(plys, self.OreInput)
			Inventory.Networking.UpdateInventory(ply, inv)
			self.Status:Network()
		end, GenerateErrorer("RefineryPromise"))
	else

		if slot > self.OreInput.MaxItems then print("slot higher than max", slot, self.OreInput.MaxItems) return end
		if self.OreInput.Slots[slot] then print("there's already an item in that slot") return end

		local ok, pr = xpcall(self.AddInputItem, GenerateErrorer("Refinery"),
			self, inv, item, slot)
		if not ok then return end

		pr:Then(function()
			if not IsValid(self) then return end

			self.Status:Set(slot, CurTime())
			item:SetAmount(item:GetAmount() - 1)
			local plys = Filter(ents.FindInPVS(self), true):Filter(IsPlayer)
			self.Status:Network()

			Inventory.Networking.NetworkInventory(plys, self.OreInput)
			Inventory.Networking.UpdateInventory(ply, inv)
		end, GenerateErrorer("RefineryPromise"))

	end

	--[[self.OreInput:NewItem(item:GetItemID(), function(new)

	end, slot, item:GetData(), true)]]
end

-- deposit request
net.Receive("OreRefinery", function(len, ply)
	if not ply:Alive() then return end

	local ent = net.ReadEntity()
	local self = ent

	local inv = Inventory.Networking.ReadInventory()
	local item = Inventory.Networking.ReadItem(inv)

	if not inv.IsBackpack then print("inventory is not a backpack") return end
	if not item then print("didn't get item") return end

	local bulk = net.ReadBool()

	if bulk then
		ent:QueueRefine(ply, inv, item, nil, bulk)
		return
	end

	local slot = net.ReadUInt(16)
	ent:QueueRefine(ply, inv, item, slot, bulk)

end)

function ENT:SendInfo()
	print("SendInfo called", CurTime())
	Inventory.Networking.NetworkInventory(Filter(ents.FindInPVS(self), true):Filter(IsPlayer), self.Inventory, INV_NETWORK_FULLUPDATE)
end

function ENT:Use(ply)
	Inventory.Networking.NetworkInventory(ply, self.Inventory)
	net.Start("OreRefinery")
		net.WriteEntity(self)
		net.WriteUInt(0, 4)
	net.Send(ply)
end