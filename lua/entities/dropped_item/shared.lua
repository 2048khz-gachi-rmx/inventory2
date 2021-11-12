AddCSLuaFile()
ENT.Base = "base_gmodentity"
ENT.Type = "anim"
ENT.PrintName = "Base Dropped Item"

ENT.Model = "models/props_borealis/bluebarrel001.mdl"
ENT.Skin = 0
ENT.TimeToPickupable = 2.3
ENT.TimeToAnimate = 0.7

local function notInitted(self)
	if self._Initialized then
		error("do it before spawn")
		return
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "DropOrigin")
	self:NetworkVar("Float", 0, "CreationTime")
	self:NetworkVar("Int", 0, "NWItemID")
end

function ENT:SetItem(itm)
	notInitted(self)
	CheckArg(1, itm, IsItem, "Item")
	self.Item = itm
end

function ENT:Initialize()
	self._Initialized = true

	if CLIENT then
		self:CLInit()
	else
		self:SVInit()
	end
end
