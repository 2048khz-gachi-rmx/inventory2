--don't construct item objects directly; use Inventory.NewItem instead
local it = Inventory.ItemObjects.Generic or Emitter:extend()
it.ClassName = "Generic"
it.IsItem = true

Inventory.ItemObjects.Generic = it

it.__tostring = function(self)
	return ("%s '%s' | ItemID: %s, ItemUID: %s"):format(
		self.ClassName or "Missing class!",
		self.ItemName or "Missing ItemName!",
		self.ItemID or "Missing ItemID!",
		self.ItemUID or "Unassigned ItemUID"
	)
end

function it:OnExtend(new, name)
	if not isstring(name) then error("ItemClass extensiosns _MUST_ have a name assigned to them!") return end
	new.ClassName = name
end

function it:Initialize(uid, iid, ...)
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
	self:SetValid(true)

	local base = Inventory.BaseItems[iid]

	if not base then
		errorf("Failed to find Base Item for Item: UID: %s, IID: %d", uid or "[none]", iid)
	end

	base:Emit("CreatedInstance", self)

	--self:ChangeInitArgs(uid, ...)
end

local function equalData(dat1, dat2)
	for k,v in pairs(dat1) do
		if dat2[k] ~= v and k ~= "Amount" then
			return false
		end
	end
	return true
end

function it:CanStack(it2, amt, stackIn)
	if not equalData(self.Data, it2.Data) then print("inequal data") return false end
	if self:GetItemID() ~= it2:GetItemID() then print("not same iid") return false end
	if self:GetAmount() == self:GetMaxStack() then print("already max", self:GetAmount(), self:GetMaxStack()) return false end

	return math.min(self:GetMaxStack() - self:GetAmount(), it2:GetAmount(), amt or math.huge)
end

function it:Delete()
	if self:GetInventory() then
		self:GetInventory():RemoveItem(self)
	end
	self:SetValid(false)
	if SERVER then Inventory.MySQL.DeleteItem(self) end
end

it.IsValid = it.GetValid

function it:SetOwner(ply)
	self.Owner = ply
	self.OwnerUID = ply:SteamID64()
end

ChainAccessor(it, "ItemUID", "ItemUID")
ChainAccessor(it, "ItemUID", "UID")

ChainAccessor(it, "UIDIsFake", "UIDFake")

ChainAccessor(it, "ItemID", "ItemID")
ChainAccessor(it, "ItemID", "IID")
ChainAccessor(it, "Known", "Known")
ChainAccessor(it, "_Valid", "Valid")

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
BaseItemAccessor(it, "ModelColor", "ModelColor")
BaseItemAccessor(it, "FOV", "FOV")
BaseItemAccessor(it, "CamPos", "CamPos")
BaseItemAccessor(it, "LookAng", "LookAng")
BaseItemAccessor(it, "ShouldSpin", "ShouldSpin")

BaseItemAccessor(it, "Countable", "Countable")
BaseItemAccessor(it, "MaxStack", "MaxStack")


function it:GetBaseItem()
	return Inventory.Util.GetBase(self.ItemID)
end
it.GetBase = it.GetBaseItem


ChainAccessor(it, "Inventory", "Inventory")

function it:SetSlot(slot, sql)
	self.Slot = slot

	local inv = self:GetInventory()

	if inv then
		inv:SetSlot(self, slot)

		if SERVER and self:GetSQLExists() and sql ~= false then
			Inventory.MySQL.SetSlot(self, inv)
		end
	end

end

function it:GetSlot()
	return self.Slot
end

function it:ReadNetworkedVars()
	local base = self:GetBaseItem()

	for k,v in ipairs(base.NetworkedVars) do
		local read = net.ReadBool()
		if not read then print("no networked vars") continue end

		if isfunction(v.what) then
			v.what(self, false)
		else
			self.Data[v.what] = net["Read" .. v.type] (unpack(v.args))
			print("also read:", "Read" .. v.type, unpack(v.args))
		end
	end

end


function it:Register(addstack)
	hook.Run("ItemClassRegistered", self, self.ClassName)
	Inventory.RegisterClass(self.ClassName, self, Inventory.ItemObjects, (addstack or 0) + 1)
end

it:Register()

if SERVER then
	include("generic_item_sv_extension.lua")
else
	include("generic_item_cl_extension.lua")
end