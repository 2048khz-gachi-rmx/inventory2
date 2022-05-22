--don't construct item objects directly; use Inventory.NewItem instead
local it = Inventory.ItemObjects.Generic or Emitter:extend()
it.ClassName = "Generic"
it.IsItem = true

Inventory.ItemObjects.Generic = it

if SERVER then include("sv_persistence_ext.lua") end

it.__tostring = function(self)
	return ("%s '%s' | ItemID: %s, ItemUID: %s"):format(
		self.ClassName or "Missing class!",
		self.ItemName or "Missing ItemName!",
		self.ItemID or "Missing ItemID!",
		self.ItemUID or "Unassigned ItemUID"
	)
end

local TOKEN = uniq.Seq("InvTokens", 16)

function it:OnExtend(new, name)
	if not isstring(name) then error("ItemClass extensiosns _MUST_ have a name assigned to them!") return end
	new.ClassName = name
end

function it:GetToken() return TOKEN end
function Inventory.GetToken() return TOKEN end

function it:IncrementToken()
	TOKEN = uniq.Seq("InvTokens", 16)
	return TOKEN
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
	self.NWID = -1

	self._Commited = {
		Delete = {},
		Move = {},
		CrossInv = {}
	}

	self:SetValid(true)

	if SERVER then
		self.IPersistence = Inventory.ItemPersistence:new(self)
	end

	local base = Inventory.BaseItems[iid]

	if not base then
		errorf("Failed to find Base Item for Item: UID: %s, IID: %d", uid or "[none]", iid)
	end

	base:Emit("CreatedInstance", self)

	--self:ChangeInitArgs(uid, ...)
end

function it:GetNWID()
	if self.NWID == -1 and SERVER then
		self.NWID = uniq.Seq("ItemNWID")
	end

	return self.NWID
end

function it:SetNWID(n)
	self.NWID = n
end

local function equalData(dat1, dat2)
	for k,v in pairs(dat1) do
		if dat2[k] ~= v and k ~= "Amount" then
			return false
		end
	end
	return true
end

function it:GetCommitedActions(typ)
	return self._Commited[typ]
end

-- first arg can also be a table of data
-- can stack it2 into self?

function it:CanStack(it2, amt)
	local otherData = IsItem(it2) and it2:GetData() or istable(it2) and it2
	it2 = IsItem(it2) and it2

	if otherData and not equalData(self.Data, otherData) then return false end
	if it2 and self:GetItemID() ~= it2:GetItemID() then return false end
	if not self:GetMaxStack() or (it2 and not it2:GetMaxStack()) then return false end
	if self:GetAmount() == self:GetMaxStack() then return false end

	return math.min(self:GetMaxStack() - self:GetAmount(),
		it2 and it2:GetAmount() or amt or math.huge,
		amt or math.huge)
end

function it:Stack(it)
	local amt = isnumber(it) or it:GetAmount()
	local toStk = math.min(self:GetMaxStack() - self:GetAmount(), amt)
	self:SetAmount(self:GetAmount() + toStk)

	return amt - toStk
end

function it:Delete()
	if self:GetInventory() then
		self:GetInventory():RemoveItem(self)
	end
	self:SetValid(false)
	if SERVER then
		self.IPersistence:Delete()
	end

	self._Commited.Delete[self:IncrementToken()] = true
end

function it:TakeOut()
	if self:GetInventory() then
		self:GetInventory():RemoveItem(self)
	end
end


function it:SetOwner(ply)
	self.Owner = ply
	self.OwnerUID = ply:SteamID64()
end

ChainAccessor(it, "ItemUID", "ItemUID")
ChainAccessor(it, "ItemUID", "UID")

ChainAccessor(it, "UIDIsFake", "UIDFake")

ChainAccessor(it, "ItemID", "ItemID")
ChainAccessor(it, "ItemID", "IID")

ChainAccessor(it, "ItemName", "ItemName")
ChainAccessor(it, "ItemName", "IName")



ChainAccessor(it, "Known", "Known")
ChainAccessor(it, "_Valid", "Valid")
it.IsValid = it.GetValid

function it:GetData() --only a getter
	return self.Data
end

it.GetPermaData = it.GetData

DataAccessor(it, "Amount", "Amount", function(it, amt)
	if amt == 0 then
		print("item ran out of amount (amt = ", amt, ", ", it, "), deleting...")
		it:Delete()
	end
end)

BaseItemAccessor(it, "Name", "Name")
BaseItemAccessor(it, "Deletable", "Deletable")

BaseItemAccessor(it, "Model", "Model")
BaseItemAccessor(it, "ModelColor", "ModelColor")
BaseItemAccessor(it, "FOV", "FOV")
BaseItemAccessor(it, "CamPos", "CamPos")
BaseItemAccessor(it, "LookAng", "LookAng")
BaseItemAccessor(it, "ShouldSpin", "ShouldSpin")

BaseItemAccessor(it, "Countable", "Countable")
BaseItemAccessor(it, "MaxStack", "MaxStack")
BaseItemAccessor(it, "Rarity", "Rarity")
BaseItemAccessor(it, "BaseTransferCost", "BaseTransferCost")

function it:GetTransferCost()
	return self:GetBase():GetBaseTransferCost()
end

function it:GetTotalTransferCost(amt)
	return self:GetTransferCost() * (amt or self:GetAmount() or 1)
end

function it:GetBaseItem()
	return Inventory.Util.GetBase(self.ItemID)
end
it.GetBase = it.GetBaseItem


--[[function it:SetInventory(inv)
	if inv == nil then
		errorNHf("attempt to set to nil inventory!!!")
	end

	self.Inventory = inv
end]]

ChainAccessor(it, "Inventory", "Inventory")

function it:SetSlot(slot, sql)
	local inv = self:GetInventory()

	if inv then
		slot = inv:_SetSlot(self, slot)
	end

	self.Slot = slot

	if inv and SERVER and self:GetSQLExists() and sql ~= false then
		-- Inventory.MySQL.SetSlot(self, inv)
		self.IPersistence:SaveSlot(slot, inv)
	end
end

function it:SwapSlots(slot)
	if self:GetSlot() == slot then return false end

	local inv = self:GetInventory()

	local it2 = inv and inv:GetItemInSlot(slot)
	local b4slot = self:GetSlot()

	self:SetSlot(slot)
	if it2 then it2:SetSlot(b4slot) end
end

function it:SetSlotRaw(slot)
	self.Slot = slot
end

function it:GetSlot()
	return self.Slot
end

function it:ReadNetworkedVars()
	local base = self:GetBaseItem()

	for k,v in ipairs(base.NetworkedVars) do
		local read = net.ReadBool()
		if not read then continue end

		if isfunction(v.what) then
			v.what(self, false)
		else
			self.Data[v.what] = net["Read" .. v.type] (unpack(v.args))
		end
	end

end


function it:Register(addstack)
	hook.Run("ItemClassRegistered", self, self.ClassName)
	Inventory.RegisterClass(self.ClassName, self, Inventory.ItemObjects, (addstack or 0) + 1)
end

it:Register()

include("generic_item_" .. Rlm(true) .. "_extension.lua")
