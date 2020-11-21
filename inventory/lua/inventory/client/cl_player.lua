

function Inventory.LoadClient()
	print("Inventory loading on client...")
	local me = LocalPlayer()
	me.Inventory = {}

	for k,v in pairs(Inventory.Inventories) do
		if hook.Call("PlayerAddInventory", me, me.Inventory, v) == false or v:Emit("PlayerCanAddInventory", me) == false then continue end
		me.Inventory[k] = v:new(me)
	end

	Inventory.Networking.Resync()
end

if Inventory.Initted then
	Inventory.LoadClient()
else
	hook.Add("InventoryReady", "InventoryReady", Inventory.LoadClient)
end