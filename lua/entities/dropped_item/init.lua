include("shared.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

util.AddNetworkString("dropped_item_itm")

local sfx = {
	common = 4,
	uncommon = 4,
	rare = 3
}

function ENT:SVInit()
	if not self.Item and SERVER then
		self:Remove()
		errorf("missing item")
		return
	end

	self:SetCreatedTime(CurTime())
	self:SetModel(self.Model)
	self:SetSkin(self.Skin)

	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:GetPhysicsObject():EnableMotion(false)
	self:SetRenderMode(RENDERMODE_TRANSALPHA)

	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

	self:SetUseType(SIMPLE_USE)

	--self:PhysWake()
	self:Activate()
	self:Timer("AutoRemoval", Inventory.DropCleanupTime, 1, function()
		self:Remove()
	end)


	self:Timer("sfx", self.TimeToAnimate, 1, function()
		local itm = self:GetItem()
		if not itm then return end

		local rar = itm:GetRarity()
		if not rar then return end
		if not sfx[rar:GetID()] then print("no sfx for", rar:GetID()) return end

		local play = (self:EntIndex() % sfx[rar:GetID()]) + 1

		print("playing", "grp/items/imp_" .. rar:GetID() .. play .. ".mp3")
		self:EmitSound("grp/items/imp_" .. rar:GetID() .. play .. ".mp3",
			80, 100, 1)
	end)
end

function ENT:Think()
	if not self:CanInteract() then return end
	if self.Setup then return end

	self.Setup = true
	self:SetTrigger(true)
end

function ENT:GetItem()
	return self.Item
end

function ENT:StartTouch(e)
	if not self:CanInteract() then return end
	if not IsPlayer(e) then return end

	local tempInv = Inventory.GetTemporaryInventory(e)
	local left, pr, newIts = tempInv:PickupItem(self:GetItem())

	if not pr then
		return
	end

	if not left then
		self.PickedUp = true
		self:Remove()
	end

	pr:Then(function()
		if not IsValid(e) then return end
		e:NetworkInventory(tempInv, INV_NETWORK_UPDATE)
	end)
end

function ENT:EndTouch(e)

end

function ENT:OnRemove()
	if not self.Item then return end
	if self.PickedUp then return end

	self.Item:Delete()
end