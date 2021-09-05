AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("bp_menu.lua")
AddCSLuaFile("recipe_menu.lua")

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

end

util.AddNetworkString("Workbench")

function ENT:SendInfo(ply)
	net.Start("Workbench")
		net.WriteBool(false)
		net.WriteEntity(self)
	net.Send(ply)
end

function ENT:Use(ply)
	self:SendInfo(ply)
end


function ENT:DoBlueprintCraft(ply, bp)
	local recipe = bp:GetRecipe()

	local invs = Inventory.Util.GetUsableInventories(ply)

	for id, amt in pairs(recipe) do
		if Inventory.Util.GetItemCount(invs, id) < amt then
			return false, "Not enough of item: " .. id
		end
	end

	print("cool enough of every item")

	for id, amt in pairs(recipe) do
		local ok = Inventory.TakeItems(invs, id, amt)
		if not ok then return end
	end

	local pr = bp:CreateResult(ply)
	bp:Delete()

	pr:Then(function()
		ply:UI()
	end)
end

net.Receive("Workbench", function(_, ply)
	local nw = Inventory.Networking
	local pr = net.ReplyPromise(ply)
	local ent = net.ReadEntity()


	if not IsValid(ent) or not ent.IsWorkbench or ply:GetPos():Distance(ent:GetPos()) > 256 then return end
	if not ent:BW_IsOwner(ply) then return end

	local ns = netstack:new()


	local bp = net.ReadBool()

	if bp then
		-- crafting from blueprint
		local it = nw.ReadItem(nw.ReadInventory())
		if not it or not it.IsBlueprint then
			print("not valid item", ply, it, it and it.Blueprint)
			return
		end

		local ok, err = ent:DoBlueprintCraft(ply, it)

		pr:Reply(ok, ns)
		if err then
			ns:WriteString(err)
		end

		net.Start("Workbench")
			net.WriteBool(true)
			net.WriteNetStack(ns)
		net.Send(ply)

		print("crafting from blueprint", it, it:GetRecipe())
	else
		-- crafting a recipe
	end
end)