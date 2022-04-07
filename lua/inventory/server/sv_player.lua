local PLAYER = FindMetaTable("Player")

function PLAYER:InitializeInventories()
	self.Inventory = {}

	local prs = {}

	for k,v in pairs(Inventory.Inventories) do
		if hook.Call("PlayerAddInventory", self, self.Inventory, v) == false or v:Emit("PlayerCanAddInventory", me) == false then continue end
		self.Inventory[k] = v:new(self)
		--prs[#prs + 1] = self.Inventory[k].FetchPr -- hack but aight
	end

	Inventory.MySQL.FetchPlayerItems(false, self):Then(function()
		-- only update if we fetched their items after they wanted a resync, somehow
		if not self.InventoryEverSynced then return end
		Inventory.Log("Fetched all items for %q", self:Nick())

		Inventory.Networking.NetworkItemNames(self)
		Inventory.Networking.NetworkInventory(self)
	end)


	Inventory.Log("Initialized inventories for %q", self:Nick())

	if Inventory.InDev then
		self.bp = self.Inventory.Backpack
		self.its = self.Inventory.Backpack.Items

		local invs = {}
		for k,v in pairs(self.Inventory) do invs[k] = v end

		self.invun = UnionTable(invs)
		self.inv = self.Inventory
	end
end

hook.Add("InventoryItemIDsReceived", "PlayerInitInventories", function()
	hook.Add("PlayerInitialSpawn", "Inventory", function(ply)
		ply:InitializeInventories()
	end)
	UnionTable(player.GetAll()):InitializeInventories()
end)

-- UnionTable(player.GetAll()):InitializeInventories()