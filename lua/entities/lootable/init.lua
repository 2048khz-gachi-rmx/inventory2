include("shared.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

util.AddNetworkString("lootable")

local DefaultLootpool = "lootable_low_small"

function ENT:SetLootPool(name, amt)
	if not Inventory.LootGen.Pools[name] then
		errorNHf("no lootgen pool: %s", name)
		return
	end

	self.LootPool = Inventory.LootGen.Pools[name]
	self.LootAmount = amt
end

function ENT:GenerateLoot(amt)
	local its = Inventory.LootGen.Generate(self.LootPool, amt)

	local prs = {}

	for k,v in pairs(its) do
		prs[#prs + 1] = self.Storage:InsertItem(v, k)
	end

	return Promise.OnAll(prs)
end

function ENT:SVInit()
	if not self.LootPool then
		errorNHf("set a lootpool before spawning (using default: %s)", DefaultLootpool)
		self:SetLootPool(DefaultLootpool)
	end

	self:SetModel(self.Model)
	self:SetSkin(self.Skin)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:GetPhysicsObject():EnableMotion(false)
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetUseType(SIMPLE_USE)

	--self:PhysWake()
	self:Activate()
	self:GenerateLoot(self.LootAmount or math.random(3, 5)):Then(function()
		self.Storage:On("Change", "Lootable", function()
			self:InvChanged()
		end)
	end)
end

function ENT:Think()

end

function ENT:OnRemove()
	self.Storage:RemoveListener("Change", "LootableNW")

	for k,v in pairs(self.Storage:GetItems()) do
		v:Delete()
	end
end

function ENT:Use(ply)
	if not IsPlayer(ply) then return end

	--ply:NetworkInventory(self.Storage)
end

function ENT:NetworkInv(ply, full)
	Inventory.Networking.NetworkInventory(ply, self.Inventory, full and INV_NETWORK_FULLUPDATE or INV_NETWORK_UPDATE)
end

function ENT:InvChanged()
	if table.IsEmpty(self.Storage:GetItems()) then
		self:Remove()
		return
	end

	self:NetworkInv(self:GetSubscribers())
end

function ENT:PlayerUnsub(ply)
	print("unsubbed", ply)
end

function ENT:PlayerRequest(ply)
	local ok = self:Subscribe(ply, 128, self.PlayerUnsub)
	if ok then
		self:NetworkInv(ply, true)
	end
end

net.Receive("lootable", function(_, ply)
	local ent = net.ReadEntity()
	if not IsValid(ent) or not ent.IsLootableBoks then print("fuck you get owned", ent, ent.IsLootableBoks) return end

	ent:PlayerRequest(ply)
end)

if not Inventory or not Inventory.Initted then
	hook.Add("InventoryReady", "LootableLoad", function()
		include("entities/lootable/loot_gen.lua")
	end)
else
	include("entities/lootable/loot_gen.lua")
end