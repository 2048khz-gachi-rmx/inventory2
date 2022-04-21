Inventory.Networking = Inventory.Networking or {InventoryIDs = {}}
local nw = Inventory.Networking

util.AddNetworkString("InvNotify")

nw.NotifyHandlers = nw.NotifyHandlers or {}

function nw.AddNotifyHandler(typ, fn)
	nw.NotifyHandlers[typ] = fn
end

function nw.NotifyItemChange(ply, typ, ...)
	CheckArg(2, typ, "number")

	if not nw.NotifyHandlers[typ] then
		errorNHf("no handler for typ %s", typ)
		return
	end

	net.Start("InvNotify")
		net.WriteUInt(typ, 8)
		nw.NotifyHandlers[typ](ply, ...)
	net.Send(ply)
end


nw.AddNotifyHandler(INV_NOTIF_PICKEDUP, function(ply, iid, amt)
	net.WriteUInt(Inventory.Util.ItemNameToID(iid), 16)
	net.WriteInt(amt or 1, 16)
end)

nw.AddNotifyHandler(INV_NOTIF_TAKEN, function(ply, iid, amt)
	net.WriteUInt(Inventory.Util.ItemNameToID(iid), 16)
	net.WriteUInt(amt or 1, 16)
end)