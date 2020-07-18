Inventory.Modifiers = Inventory.Modifiers or {}
local mods = Inventory.Modifiers


mods.Pool = mods.Pool or {}

mods.Pool.Blazing = {
	MaxTier = 4,
}

mods.Pool.Crippling = {
	MaxTier = 3,
}






mods.IDConv = mods.IDConv or {ToName = {--[[ id = name ]]}, ToID = {--[[ name = id ]]}}

if SERVER then
	util.AddNetworkString("InventoryModifiers")

	function mods.EncodeMods()
		for k,v in pairs(mods.Pool) do
			if mods.IDConv.ToID[k] then continue end
			local max = #mods.IDConv.ToName

			mods.IDConv.ToName[max + 1] = k
			mods.IDConv.ToID[k] = max + 1

			v.ID = max + 1
		end
	end

	function mods.Send(ply)
		net.Start("InventoryModifiers")
			net.WriteUInt(#mods.IDConv.ToName, 16)
			for i=1, #mods.IDConv.ToName do
				net.WriteString(mods.IDConv.ToName[i])
			end
		net.Send(ply)
	end

	hook.Add("PlayerFullyLoaded", "NetworkModIDs", function(ply)
		mods.EncodeMods()
		mods.Send(ply)
	end)


	mods.EncodeMods()
	mods.Send(player.GetAll())
else

	net.Receive("InventoryModifiers", function()
		local amt = net.ReadUInt(16)

		for i=1, amt do
			local name = net.ReadString()
			if mods.Pool[name] then
				mods.Pool[name].ID = i

				mods.IDConv.ToID[name] = i
				mods.IDConv.ToName[i] = name
			else
				print("Modifiers: missed mod with name:", name, i)
			end
		end
	end)
end


function mods.IDToName(id)
	return mods.IDConv.ToName[id]
end

function mods.NameToID(name)
	return mods.IDConv.ToID[name]
end