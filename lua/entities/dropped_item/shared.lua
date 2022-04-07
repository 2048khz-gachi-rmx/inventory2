AddCSLuaFile()
ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "Base Dropped Item"
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.Model = "models/hunter/blocks/cube075x075x075.mdl"
ENT.Skin = 0
ENT.TimeToPickupable = 1.6
ENT.TimeToAnimate = .7

local function notInitted(self)
	if self._Initialized then
		error("do it before spawn")
		return
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "DropOrigin")
	self:NetworkVar("Float", 0, "CreatedTime")
	self:NetworkVar("Int", 0, "NWItemID")
end

function ENT:SetItem(itm)
	notInitted(self)
	CheckArg(1, itm, IsItem, "Item")
	assert(itm:GetUID(), "can't set an item without a UID!")

	local ns = Inventory.WriteItem(itm)

	net.Start("dropped_item_itm")
		net.WriteNetStack(ns)
	net.Broadcast()

	self.Item = itm
	self:SetNWItemID(itm:GetUID())
end

function ENT:CanInteract()
	return (CurTime() - self:GetCreatedTime()) > self.TimeToPickupable
end

function ENT:Initialize()
	self:DrawShadow(false)
	self._Initialized = true

	self.Inventory = {Inventory.Inventories.Entity:new(self)}

	if CLIENT then
		self:CLInit()
	else
		self:SVInit()
	end
end
