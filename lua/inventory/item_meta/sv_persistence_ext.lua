local IP = Inventory.ItemPersistence or Emitter:extend()
Inventory.ItemPersistence = IP

local ms = Inventory.MySQL
local qg = ms.QueryGen

ChainAccessor(IP, "_itm", "Item")

function IP:Initialize(itm)
	CheckArg(1, itm, IsItem, "item")

	self.UIDAssigned = Promise()
	self.m = muldim:new()
	self:SetItem(itm)

	if itm:GetUID() then
		self.UIDAssigned:Resolve()
	else
		itm:Once("AssignUID", "Persistence", self.UIDAssigned:Resolver())
	end
end

function IP:_FlushQueries(tr)
	self._pending = false
	if self.Deleted then
		Inventory.MySQL.DeleteItem(self:GetItem())
		return
	end

	local ch = self.m:Get("DataToSave")

	if ch then
		local qry = Inventory.MySQL.QueryGen.SetData(self:GetItem(), ch)
		tr:addQuery(qry)
	end

	if self.SlotChange then
		--local qry = qg.SetSlot(self:GetItem():GetSlot(), self:GetItem(), self:GetItem():GetInventory())
		local qry = qg.Setinventory(self:GetItem(), self:GetItem():GetInventory(), self:GetItem():GetSlot())
		tr:addQuery(qry)
	end
end

function IP:QueryChange()
	if self._pending then return end
	self._pending = true

	self.UIDAssigned:Then(function()
		Inventory:Once("FlushSQL", self, function(_, tr)
			self:_FlushQueries(tr)
		end)
	end)

	--Inventory.MySQL.QueryGen.SetData(self, k)
end

IP.IsValid = TrueFunc

-- "Amount", 5
function IP:SaveData(k, v)
	local ch = self.m:GetOrSet("DataToSave")

	if istable(k) then
		for k2, v2 in pairs(k) do
			ch[k2] = v2
		end
	else
		ch[k] = v
	end

	self:QueryChange()
	--[[self.UIDAssigned:Once("Resolved", "DataSave", function()
		Inventory.MySQL.ItemSetData(self:GetItem(), ch)
		self.m:Remove("DataToSave")
	end)]]
end

function IP:SaveSlot(inv)
	self.SlotChange = true
	self:QueryChange()
end
IP.SavePos = IP.SaveSlot

function IP:Delete()
	self.Deleted = true
	self:QueryChange()
end

timer.Create("InvFlush", 1, 0, function()
	local t = ms.DB:createTransaction()
	Inventory:Emit("FlushSQL", t)

	local amt = t:getQueries()
	if #amt == 0 then return end -- nvm

	MySQLEmitter(t, true)
		:Catch(ms.TransactionError)
end)