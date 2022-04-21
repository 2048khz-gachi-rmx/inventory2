

function Inventory.LoadClient()
	local me = LocalPlayer()
	me.Inventory = {}

	for k,v in pairs(Inventory.Inventories) do
		if hook.Run("PlayerAddInventory", me, me.Inventory, v) == false or v:Emit("PlayerCanAddInventory", me) == false then continue end
		me.Inventory[k] = v:new(me)

		hook.Run("PlayerCreatedInventory", me, me.Inventory[k])
	end

	if Inventory.InDev then
		me.bp = me.Inventory.Backpack
		me.its = me.Inventory.Backpack.Items

		local invs = {}
		for k,v in pairs(me.Inventory) do invs[k] = v end

		me.invun = UnionTable(invs)
		me.inv = me.Inventory
	end

	Inventory.Networking.Resync()
end

if Inventory.Initted then
	Inventory.LoadClient()
else
	hook.Add("InventoryReady", "InventoryReady", Inventory.LoadClient)
end