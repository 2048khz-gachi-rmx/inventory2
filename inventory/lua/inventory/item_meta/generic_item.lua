--don't construct item objects directly; use Inventory.NewItem instead

local it = Inventory.ItemObjects.Generic or Emitter:extend()
it.ClassName = "Generic Item"
it.IsItem = true

Inventory.ItemObjects.Generic = it

it.__tostring = function(self)
	return ("%s '%s' | ItemID: %s, ItemUID: %s"):format(self.ClassName or "Missing class!", self.ItemName or "Missing ItemName!", self.ItemID or "Missing ItemID!", self.ItemUID or "Unassigned ItemUID")
end

function it:Initialize(uid, iid)

	assert(iid, "ItemID must be provided when constructing an item object!")

	if isstring(iid) then --ItemName provided instead of ItemID
		self.ItemName = iid
		self.ItemID = Inventory.Util.ItemNameToID(iid)
	else
		self.ItemID = iid
		self.ItemName = Inventory.Util.ItemIDToName(iid)
	end

	self.ItemUID = uid
	self.Data = {}
	self.LastNetworkedVars = {}

	local base = Inventory.BaseItems[iid]
	if not base then
		errorf("Failed to find Base Item for Item: UID: %s, IID: %d", uid or "[none]", iid)
	end

	base:Emit("CreatedInstance", self)
end

local function equalData(dat1, dat2)
	for k,v in pairs(dat1) do
		if dat2[k] ~= v and k ~= "Amount" then
			return false
		end
	end
	return true
end

function it:CanStack(it2)
	if not equalData(self.Data, it2.Data) then return false end
	if self:GetAmount() == self:GetMaxStack() then return false end

	return math.min(self:GetMaxStack() - self:GetAmount(), it2:GetAmount())
end

function it:Delete()
	if self:GetInventory() then
		self:GetInventory():RemoveItem(self)
	end
	if SERVER then Inventory.MySQL.DeleteItem(self) end
end
function it:SetOwner(ply)
	self.Owner = ply
	self.OwnerUID = ply:SteamID64()
end

ChainAccessor(it, "ItemUID", "ItemUID")
ChainAccessor(it, "ItemUID", "UID")

ChainAccessor(it, "ItemID", "ItemID")
ChainAccessor(it, "ItemID", "IID")
ChainAccessor(it, "Known", "Known")

function it:GetData() --only a getter
	return self.Data
end
it.GetPermaData = it.GetData

DataAccessor(it, "Amount", "Amount", function(it, amt)
	if amt == 0 then
		it:Delete()
	end
end)

BaseItemAccessor(it, "Name", "Name")
BaseItemAccessor(it, "Name", "NiceName")
BaseItemAccessor(it, "Deletable", "Deletable")

BaseItemAccessor(it, "Model", "Model")
BaseItemAccessor(it, "FOV", "FOV")
BaseItemAccessor(it, "CamOffset", "CamOffset")
BaseItemAccessor(it, "LookAng", "LookAng")

BaseItemAccessor(it, "Countable", "Countable")
BaseItemAccessor(it, "MaxStack", "MaxStack")

function it:GetBaseItem()
	return Inventory.BaseItems[self.ItemID]
end
it.GetBase = it.GetBaseItem


ChainAccessor(it, "Inventory", "Inventory")

function it:SetSlot(slot)
	self.Slot = slot
	local inv = self:GetInventory()
	if inv then
		inv:SetSlot(self, slot)
	end
end

function it:GetSlot()
	return self.Slot
end

function it:ReadNetworkedVars()
	local base = self:GetBaseItem()

	for k,v in ipairs(base.NetworkedVars) do
		local read = net.ReadBool()
		if not read then continue end

		if isfunction(v.type) then
			v.type(self, false)
		else
			self.Data[v.what] = net["Read" .. v.type] (unpack(v.args))
		end
	end

end

if SERVER then include("generic_item_sv_extension.lua") end