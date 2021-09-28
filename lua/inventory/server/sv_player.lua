local PLAYER = FindMetaTable("Player")

function PLAYER:InitializeInventories()
    self.Inventory = {}

    for k,v in pairs(Inventory.Inventories) do
        if hook.Call("PlayerAddInventory", self, self.Inventory, v) == false or v:Emit("PlayerCanAddInventory", me) == false then continue end
        self.Inventory[k] = v:new(self)
    end

    Inventory.Log("Initialized inventory for %q", self:Nick())

    if Inventory.InDev then
        self.bp = self.Inventory.Backpack
        self.its = self.Inventory.Backpack.Items
        self.invun = UnionTable(self.Inventory)
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