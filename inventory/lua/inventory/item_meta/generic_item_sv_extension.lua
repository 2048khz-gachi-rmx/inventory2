local it = Inventory.ItemObjects.Generic

function it:WriteNetworkedVars(ns, typ)
	local base = self:GetBaseItem()
	for k,v in ipairs(base.NetworkedVars) do

		--for every custom-encoded var, there is a bool written before the actual content
		--was the data even written or nah? did it exist, or did the function return anything?
		--if nah, the decoder will skip this particular var

		if isfunction(v.what) then
			local ret = v.what(self, true) --true means write, false means read
			if not IsNetStack(ret) then ns:WriteBool(false) continue end

			ns:WriteBool(true).PacketName = "Has NetworkedVar as function - " .. tostring(self)
			ret:MergeInto(ns)
		else
			if not self.Data[v.what] or (typ ~= INV_NETWORK_FULLUPDATE and self.LastNetworkedVars[v.what] == self.Data[v.what]) then ns:WriteBool(false) continue end

			ns:WriteBool(true).PacketName = "Has NetworkedVar as predefined"
			print("NetworkedVars: networking", v.what, "for", self:GetName(), "with args:", self.Data[v.what], unpack(v.args))
			ns["Write" .. v.type] (ns, self.Data[v.what], unpack(v.args)).PacketName = "NetworkedVar - " .. v.what
			self.LastNetworkedVars[v.what] = self.Data[v.what]
		end
	end
end

function it:Serialize(ns, typ)
	if not ns then
		ns = Inventory.Networking.NetStack()
	end

	ns:WriteIDs(self)
	ns:WriteSlot(self)

	self:WriteNetworkedVars(ns, typ)
	return ns
end

-- Stick the item into SQL and into the inventory automatically
function it:Insert(invobj, cb)
	if not invobj then invobj = self.Inventory or errorf("No inventory for the item to use for inserting!") end

	--local isql = invobj and invobj.SQLName

	local sid = invobj and invobj:GetOwnerID()

	local qobj = Inventory.MySQL.NewInventoryItem(self, invobj, sid)

	qobj:Once("Success", function(_, query, dat)
		local uid = query:lastInsert()
		if uid == 0 then uid = dat[1].uid end

		if cb then cb(self, uid) end
		self:SetUID(uid)
		self:SetUIDFake(false)

		if not invobj:HasItem(self) then
			invobj:AddItem(self)
		end

		self:Emit("AssignUID", uid)

	end)

	return qobj
end

-- Deserialize data from SQL (JSON)
function it:DeserializeData(dat)
	if not dat then return end

	local t = util.JSONToTable(dat)
	self.Data = t
end

--takes either a table of data to merge in
-- (for example: .Data  = {a = 2, b = 4} ; given = {a = 3, c = 5})
-- (result: .Data = {a = 3, b = 4, c = 5})

-- or a key-value pair

function it:SetData(k, v)
	local inv = self:GetInventory()

	if inv then
		inv:AddChange(self, INV_ITEM_DATACHANGED)
	end

	if istable(k) then
		for k2,v2 in pairs(k) do
			self.Data[k2] = v2
		end
		return Inventory.MySQL.ItemSetData(self, k)
	elseif not k or not v then
		errorf("it:SetData: expected table as arg #1 or key/value as #2 and #3: got %s, %s instead", type(k), type(v)) 
		return
	end

	self.Data[k] = v
	return Inventory.MySQL.ItemSetData(self, {[k] = v})
end