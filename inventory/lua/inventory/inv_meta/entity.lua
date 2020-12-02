local bp = Inventory.GetClass("inv_meta", "backpack")
if not bp then error("Something went wrong while loading Vault: backpack is missing.") return end

local ent = Inventory.Inventories.Entity or bp:extend()
Inventory.Inventories.Entity = ent

ent.UseSQL = false
ent.NetworkID = 100
ent.Name = "Base Entity Inventory"
ent.UseSlots = false
ent.MaxItems = 10
ent.AutoFetchItems = false
ent.MultipleInstances = true --there can be multiple inventory instances of the same class in a single table
ent.EntityOwner = NULL
ent.IsEntityInventory = true

ent:Register()

ChainAccessor(ent, "EntityOwner", "EntityOwner")

function ent:SetOwner(ent)
	if ent:IsPlayer() then error("A player can't be the owner of an Entity inventory!") return end

	self.Owner = ent
	self.EntityOwner = ent
	self:Emit("OwnerAssigned", ent)
end

ent:On("OwnerAssigned", "StoreEntity", function(self, ow)
	print("OwnerAssigned emitter fired")
	local hookid = ("EntInv:%p"):format(ow)
	print("Added hook", hookid)
	hook.OnceRet("CPPIAssignOwnership", hookid, function(ply, ent)
		if ent ~= self then return false end
		self.Owner = ply
		self.OwnerUID = ply:SteamID64()
	end)
end)


ent:On("PlayerCanAddInventory", "NoAutoAdd", function() -- don't add this inventory to players' inventory list
	return false
end)

function ent:HasAccess(ply)
	if not self.UseOwnership then return true end

	local ow = self.OwnerUID
	return ow == ply:SteamID64()
end