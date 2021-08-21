local bp = Inventory.GetClass("inv_meta", "backpack")
if not bp then error("Something went wrong while loading Vault: backpack is missing.") return end

local ent = Inventory.Inventories.Entity or bp:extend()
Inventory.Inventories.Entity = ent

-- ent.UseSQL = false

ent.NetworkID = 100
ent.Name = "Base Entity Inventory"
ent.SQLName = "entity"
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

	self.EntityOwner = ent
	self.__parent.SetOwner(self, ent)
end

function ent:SetPlayerOwner(ply)
	if not GetPlayerInfo(ply) then error("A non-player can't be the player-owner of an Entity inventory!") return end

	local pin = GetPlayerInfo(ply)

	self.PlayerOwner = pin:GetPlayer()
	self:SetOwnerUID(pin:GetSteamID64())
end

ent:On("OwnerAssigned", "StoreEntity", function(self, ow)
	if self.HasHook then return end
	self.HasHook = true

	local own = ow:BW_GetOwner()

	if own then
		self:SetPlayerOwner(own)
	end

	local hookid = ("EntInv:%s:%p"):format(own and own:SteamID64() or "-", self)

	hook.OnceRet("EntityOwnershipChanged", hookid, function(ply, ent)
		if not ow:IsValid() then return end -- invalid entity = remove hook
		if ent ~= ow then return false end

		-- changed owner = remove hook
		self.HasHook = false
		self:SetOwner(ent)
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

ChainAccessor(ent, "PlayerOwner", "PlayerOwner", true)
ChainAccessor(ent, "PlayerOwner", "Player", true)
ChainAccessor(ent, "Owner", "Entity", true)
ChainAccessor(ent, "Owner", "EntityOwner", true)