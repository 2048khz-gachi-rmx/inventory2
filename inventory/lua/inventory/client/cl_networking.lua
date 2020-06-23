--

local nw = Inventory.Networking or {InventoryIDs = {}}
Inventory.Networking = nw

local log = Inventory.Log

function nw.ReadHeader()
    local max_uid, max_id = net.ReadUInt(5), net.ReadUInt(5)
    return max_uid, max_id
end

function nw.ReadItem(uid_sz, iid_sz, slot_sz, inventory)
    local uid, iid = net.ReadUInt(uid_sz), net.ReadUInt(iid_sz)
    local slot = slot_sz and net.ReadUInt(slot_sz)

    local item = inventory:HasItem(uid)

    if not item then
        local meta = Inventory.Util.GetMeta(iid)
        print(iid, meta)
        item = meta:new(uid, iid)
    end

    if slot then item:SetSlot(slot) end

    inventory:AddItem(item, true)

    item:ReadNetworkedVars()
    --item:SetInventory(inventory)

    log("       Read item UID: %s; IID: %s; Slot: %s", uid, iid, slot)
    return item
end

function nw.ReadInventory(invtbl, typ)
    local max_uid, max_id = nw.ReadHeader()
    local invID = net.ReadUInt(16)
    local its = net.ReadUInt(16)

    log("CL-Networking: reading %d items for inventory %d", its, invID)

    local inv = invtbl[invID] or errorf("Could not find Inventory with ID %d in that entity!!", invID)

    AAA = invtbl
    local slot_size = inv.MaxItems and bit.GetLen(inv.MaxItems)

    for i=1, its do
        log("   reading item #%d", i)
        local it = nw.ReadItem(max_uid, max_id, slot_size, inv)
        --inv:AddItem(it)
        log("   successfully added item")
        Inventory:Emit("ItemAdded", inv, it)
    end

    if typ == INV_NETWORK_UPDATE then
        local dels = net.ReadUInt(16)

        log("CL-Networking: reading %d deletions", dels)

        for i=1, dels do
            local uid = net.ReadUInt(max_uid)
            local del_it = inv:DeleteItem(uid)
            log("   successfully deleted item")
            Inventory:Emit("ItemRemoved", inv, del_it)
        end

        local moves = net.ReadUInt(16)

        log("CL-Networking: reading %d moves", moves)

        for i=1, moves do
            local uid = net.ReadUInt(max_uid)
            local slot = net.ReadUInt(bit.GetLen(inv.MaxItems))
            log("   moving item %s into slot %s", uid, slot)
            local item = inv:GetItem(uid)
            item:SetSlot(slot)
            --log("   successfully moved item %s into slot %s", uid, slot)
            --Inventory:Emit("ItemChanged", inv, item)
            Inventory:Emit("ItemMoved", inv, item)
        end
    end

    inv:Emit("Change")
end

function nw.ReadUpdate(len, type)
    local invs = net.ReadUInt(8) --amount of inventories
    local ent = net.ReadEntity()

    log("CL-NW: Update: Received %d inventories for %s; packet length is %d", invs, ent, len)

    local invs_table = {} --map out all the entity's inventories into {[nwID] = obj} pairs

    for k,v in pairs(ent.Inventory) do

        if type == INV_NETWORK_FULLUPDATE then
            log("!!!!!DROPPING INVENTORY!!!!!")
            v:Reset()
        end

        invs_table[v.NetworkID] = v
    end

    for i=1, invs do
        nw.ReadInventory(invs_table, type)
    end
end


function nw.ReadNet(len)
    local type = net.ReadUInt(4) --type of networking (fullupdate? partial update?)

    if type == INV_NETWORK_FULLUPDATE or type == INV_NETWORK_UPDATE then
        nw.ReadUpdate(len, type)
    end

end

net.Receive("Inventory", nw.ReadNet)


function nw.ReadConstants()
    local len = net.ReadUInt(16)
    local comp = net.ReadBool()
    local dat = net.ReadData(len)

    if comp then
        dat = util.Decompress(dat)
    end
    print("Received:", dat)
    dat = von.deserialize(dat)

    local conv = Inventory.IDConversion

    for iid, iname in ipairs(dat) do
        conv.ToName[iid] = iname
        conv.ToID[iname] = iid
    end

    PrintTable(conv)
    hook.Run("InventoryIDReceived", conv.ToName, conv.ToID)
    log("CL-NW: Received & parsed inventory constants")
end


net.Receive("InventoryConstants", nw.ReadConstants)

local invnet = netstack:extend()
local log = Inventory.Log

function invnet:WriteInventory(inv)
    print('written inv', inv)
    self:WriteEntity( (inv:GetOwner()) )
    self:WriteUInt(inv.NetworkID, 16)

    self.CurrentInventory = inv

    return self
end

function invnet:WriteItem(it)
    if not self.CurrentInventory or not self.CurrentInventory:HasItem(it) then 
        errorf("Can't write an item if current inventory doesn't have it! (current inv: %s, tried to write: %s)", self.CurrentInventory, it) 
        return
    end

    self:WriteUInt(it:GetUID(), 32)
end

function nw.Netstack()
    return invnet:new()
end

function nw.PerformAction(enum, ns)
    net.Start("Inventory")
        net.WriteUInt(enum, 16)
        net.WriteNetStack(ns)
    net.SendToServer()
end

function nw.DeleteItem(it)
    local ns = Inventory.Networking.Netstack()
    ns:WriteInventory(it:GetInventory())
    ns:WriteItem(it)
    Inventory.Networking.PerformAction(INV_ACTION_DELETE, ns)
end