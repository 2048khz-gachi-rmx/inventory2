local bp = Inventory.GetClass("inv_meta", "backpack")
if not bp then error("Something went wrong while loading Vault: backpack is missing.") return end

local ent = Inventory.Inventories.Entity or bp:extend()
Inventory.Inventories.Entity = ent

-- ent.UseSQL = false

ent.IsEntityInventory = true
ent.IsPlayerInventory = false

ent.NetworkID = 100
ent.Name = "Base Entity Inventory"
ent.SQLName = "entity"
ent.UseSlots = false -- reminder that UseSlots is for SQL, not behavior
ent.MaxItems = 10
ent.AutoFetchItems = false
ent.MultipleInstances = true --there can be multiple inventory instances of the same class in a single table
ent.EntityOwner = NULL


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

	local hookid = ("EntInv:%p"):format(self)

	hook.OnceRet("EntityOwnershipChanged", hookid, function(ply, ent)
		if not ow:IsValid() then return end -- invalid entity = remove hook
		if ent ~= ow then return false end

		-- changed owner = remove hook
		self.HasHook = false
		self:SetOwner(ent)
		return false -- we put a new hook from SetOwner; dont remove this one cuz it has the same ID
	end)
end)


ent:On("PlayerCanAddInventory", "NoAutoAdd", function() -- don't add this inventory to players' inventory list
	return false
end)

local function isOwner(self, ply)
	local ow = self:GetOwnerUID()
	if ow ~= ply:SteamID64() and self.UseOwnership then return false end

	return true
end

function ent:HasAccess(ply, action, ...)
	if not isOwner(self, ply) then return false end
	return self.__parent.HasAccess(self, ply, action, ...)
end

ChainAccessor(ent, "PlayerOwner", "PlayerOwner", true)
ChainAccessor(ent, "PlayerOwner", "Player", true)
ChainAccessor(ent, "Owner", "Entity", true)
ChainAccessor(ent, "Owner", "EntityOwner", true)



local actions = {
	"Move", "Merge",
	"CrossInventoryMove", "CrossInventoryMerge"
}

for k,v in pairs(actions) do
	ent["ActionCan" .. v] = isOwner
end
