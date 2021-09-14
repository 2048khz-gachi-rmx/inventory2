
Inventory.Modifier = Inventory.Modifier or Emitter:callable()
Inventory.Modifiers = Inventory.Modifiers or {}
local mods = Inventory.Modifiers
local mod = Inventory.Modifier

mods.Pool = mods.Pool or {}

ChainAccessor(mod, "MaxTier", "MaxTier")
ChainAccessor(mod, "Name", "Name")

function mod:SetName(name)
	if self:GetName() then
		mods.Pool[self:GetName()] = nil
	end

	mods.Pool[name] = self
	self.Name = name
	return self
end

function mod:Initialize(name)
	if not name then error("modifier requires name bro") return end
	self:SetName(name)
end

function mod:GenerateMarkup() end -- for override



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

	local know = {}

	hook.Add("InventoryNetwork", "Modifiers", function(ply)
		if know[ply] or not IsPlayer(ply) then return end
		mods.EncodeMods()
		mods.Send(ply)
		know[ply] = true
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
	return (isstring(id) and mods.IDConv.ToID[id] and id) or mods.IDConv.ToName[id]
end

function mods.NameToID(name)
	return (isnumber(name) and mods.IDConv.ToName[name] and name) or mods.IDConv.ToID[name]
end

mods.ToID = mods.NameToID
mods.ToName = mods.IDToName

function mods.Get(what)
	local nm = mods.IDToName(what) or (isstring(what) and what)
	return mods.Pool[nm]
end