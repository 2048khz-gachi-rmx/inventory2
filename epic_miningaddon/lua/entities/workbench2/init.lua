AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

ENT.Model = "models/props/CS_militia/table_shed.mdl"

local me = {}


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

	me[self] = {}
	local me = me[self]

end
util.AddNetworkString("Workbench")

net.Receive("Workbench", function(_, ply)
	local it = net.ReadUInt(32)
	it = Inventory.IDToString[it]
	
	local var = net.ReadUInt(8)
	local ent = net.ReadEntity()

	if not ent or not IsValid(ent) or ent:GetClass() ~= "workbench2" then print('uh') return end --or ent:CPPIGetOwner() ~= ply then print('uh') return end 
	if not it or not Crafts[it] then print("no") return end 

	local recipe = Crafts[it]
	local mats
	local cvar = 0

	if recipe.vars then 

		for k,v in pairs(recipe.vars) do 
			if v.id == var then 
				mats = v.reqs
				cvar = v.id
				break
			end
		end

		if not mats then 
			print('didnt find var(sent:', var .. ")")
		end

	elseif recipe.reqs then 
		mats = recipe.reqs 
	else 
		print('didnt find requirements for recipe', recipe.name)
		return 
	end

	local enuff = true

	for k,v in pairs(mats) do 
		if not ply:EnoughItem(k, v) then print('player is lacking', k, v) enuff = false break end
	end


	if enuff then
		print("crafting", it, "var", cvar)
		
		for k,v in pairs(mats) do 
			local left = Inventory.SubItem(ply, k, v)
			print("mat:", k, "still needed:", left)
		end

		if not Crafts[it].perma then 
			error("what")
		end

		local vark = Crafts[it].variantname or "var"
		local prm = table.Copy(Crafts[it].perma)
		if cvar then
			table.Merge(prm, {[vark] = cvar})
		end

		ply:GiveItem(Crafts[it].id, prm)
	end


end)
util.AddNetworkString("WorkbenchGun")
net.Receive("WorkbenchGun", function(_, ply)
	local it = net.ReadUInt(32)
	local ent = net.ReadEntity()

	if not ent or not IsValid(ent) or ent:GetClass() ~= "workbench2" then print('uh') return end --or ent:CPPIGetOwner() ~= ply then print('uh') return end 
	if not it then return end

	local item = ply.Inventory[it]
	if not item or item:GetID() ~= 100000 then return end 

	print('wow creating')
	local gun = item:GetGun()

	item:DeleteItem()
	Inventory.InsertInto(ply, gun):Network()

end)

function ENT:SendInfo(ply)

	local me = RefineryTbl[self]
	
	net.Start("Workbench")
		net.WriteEntity(self)
	net.Send(ply)


end

function ENT:Use(ply)

	local me = me[self]
	if not me then self:Initialize() return end

	self:SendInfo(ply)
	
end