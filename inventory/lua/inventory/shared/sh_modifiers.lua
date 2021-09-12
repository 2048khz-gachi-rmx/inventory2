Inventory.Modifiers = Inventory.Modifiers or {}
local mods = Inventory.Modifiers


mods.Pool = mods.Pool or {}

mods.Pool.Blazing = {
	MaxTier = 4,
	Markup = function(it, mup, tier)
		local mod = mup:AddPiece()
		mod:SetAlignment(1)
		mod:AddText("Blazing")
		mod.IgnoreVisibility = true
		local bcol = Color(180, 150, 60)
		mod:SetColor(bcol)

		mod:On("Think", function()
			bcol.r = 210 + math.abs(math.sin(CurTime() * 2.3) * 40)
			bcol.g = 120 + math.abs(math.sin(CurTime() * 1.7) * 20)
		end)
		local desc = mup:AddPiece()
		desc.Font = "OS16"
		desc:DockMargin(4, 0, 0, 0)
		desc:SetColor(Color(180, 150, 60))
		desc:SetAlignment(1)
		local tx = desc:AddText("BRrrrrrrrrrrrt and you're ~ablaze~")
		desc.IgnoreVisibility = true

		local nw = desc:RewrapWidth(200)
		mup:SetWide(math.max(mup:GetWide(), nw))
		--desc:Debug()
	end
}

mods.Pool.Crippling = {
	MaxTier = 3,
	Markup = function(it, mup, tier)
		local mod = mup:AddPiece()
		mod:SetAlignment(1)
		mod.Font = "OS24"

		local t = mod:AddTag(MarkupTags("rotate", -10, 0))
		local tx = mod:AddText("Crip")

		mod:EndTag(t)
		mod:AddTag(MarkupTags("rotate", 10, 0))

		tx = mod:AddText(" pling")

		mod.IgnoreVisibility = true

		mod:On("RecalculateHeight", "RotationCorrection", function(self, buf, maxh)
			surface.SetFont(mod.Font)
			local tw, th = surface.GetTextSize("pling")
			local bw, bh = math.AARectSize(tw, th, 10)
			return math.ceil(bh)
		end)

		local desc = mup:AddPiece()
		desc.Font = "OS16"
		desc:DockMargin(8, 0, 0, 0)
		desc:SetColor(Color(130, 130, 130))
		desc:SetAlignment(1)
		local tx = desc:AddText("[NYI] Each shot applies a stacking ???% decrease to your victim's movement speed for ???s.")
		tx.WrapData = { AllowDashing = false }
		desc.IgnoreVisibility = true

		local nw = desc:RewrapWidth(250)
		mup:SetWide(math.max(mup:GetWide(), nw))
	end,
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
	return mods.IDConv.ToName[id]
end

function mods.NameToID(name)
	return mods.IDConv.ToID[name]
end

function mods.Get(what)
	local nm = mods.IDToName(what) or (isstring(what) and what)
	return mods.Pool[what]
end