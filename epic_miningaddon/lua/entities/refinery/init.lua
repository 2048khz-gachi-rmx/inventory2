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
	self._LastThink = CurTime()
end

util.AddNetworkString("OreRefinery")

function ENT:RemoveOre(slot)
	local it = self.OreInput[slot]
	self.OreInput[slot]:Delete()
end

function ENT:TimeItem(slot)
	local itm = self.OreInput:GetSlots()[slot]
	local itmStart = itm.StartedRefining or CurTime()


	if self:IsPowered() then
		-- we're powered; status value means start of refining
		-- get unpowered penalty (if any), apply and network
		local pwStart = self.Status:Get("DepowerTime", CurTime())
		local diff = CurTime() - math.max(pwStart, itmStart)

		itm.StartedRefining = itmStart + diff
		self.Status:Set(slot, itm.StartedRefining)
	else
		-- we're unpowered; status value means % refined when power was gone
		-- calculate time between "ore added" and "power shutoff"
		local passed = self.Status:Get("DepowerTime", CurTime()) - itmStart
		local frac = passed / itm:GetBase():GetSmeltTime()

		itm.StartedRefining = itmStart -- assign initial time if it didnt exist
		self.Status:Set(slot, frac)
	end
end

function ENT:OnPower()
	for k,v in pairs(self.OreInput:GetSlots()) do
		self:TimeItem(k)
	end

	self.Status:Set("DepowerTime", nil)
end

function ENT:OnUnpower()
	self.Status:Set("DepowerTime", CurTime())

	for k,v in pairs(self.OreInput:GetSlots()) do
		self:TimeItem(k)
	end
end

function ENT:Think()
	if not self:IsPowered() then
		self:NextThink(CurTime() + 0.2)
		return true
	end

	local fin_amt = {}
	local changed = false

	for k,v in pairs(self.OreInput:GetItems()) do
		local fin = v.StartedRefining + v:GetBase():GetSmeltTime()

		if CurTime() > fin then
			local smTo = v:GetBase():GetSmeltsTo()
			v:Delete()
			if not smTo then print("didn't find what", v:GetName(), " smelts to") continue end --?

			fin_amt[smTo] = (fin_amt[smTo] or 0) + 1
			changed = true
		end
	end

	local prs = {}

	for name, amt in pairs(fin_amt) do
		local pr, what = self.OreOutput:NewItem(name, function() self:SendInfo() end, nil, {Amount = amt})

		if pr then
			table.insert(prs, pr)
		end
	end

	if #prs > 0 then
		Promise.OnAll(prs):Then(function()
			if IsValid(self) then self:SendInfo() end
		end)

	elseif changed then
		self:SendInfo()
	end

	self:NextThink(CurTime() + 0.2)
	return true
end

function ENT:AddInputItem(inv, item, slot)
	local meta = Inventory.Util.GetMeta(item:GetItemID())
	local new = meta:new(nil, item:GetItemID())
	--new:SetSlot(slot)
	new:SetAmount(1)
	new:SetOwner(inv:GetOwner())
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

			item:SetAmount(item:GetAmount() - 1)
		end

		Promise.OnAll(prs):Then(function()
			if not IsValid(self) then return end

			self:TimeItem(slot)
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

			self:TimeItem(slot)
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
	local all = Filter(ents.FindInPVS(self), true):Filter(IsPlayer)
	Inventory.Networking.NetworkInventory(all, self.Inventory, INV_NETWORK_FULLUPDATE)
end

function ENT:Use(ply)
	Inventory.Networking.NetworkInventory(ply, self.Inventory)
	net.Start("OreRefinery")
		net.WriteEntity(self)
		net.WriteUInt(0, 4)
	net.Send(ply)
end