--
setfenv(0, _G)
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

function nw.ReadInventoryContents(invtbl, typ)
    local max_uid, max_id = nw.ReadHeader()

    local invID = net.ReadUInt(16)

    local inv

    for k, baseinv in pairs(Inventory.Inventories) do
        if baseinv.NetworkID == invID then
            if baseinv.MultipleInstances then
                local key = net.ReadUInt(16)
                print("multiple instances, key is", key, invtbl[key])
                inv = invtbl[key]
            else
                print("not multiple instances, key is", invID)
                inv = invtbl[baseinv.NetworkID]
            end
            break
        end
    end

    if not inv then errorf("Didn't find inventory with NetworkID %s!", invID) end

    local its = net.ReadUInt(16)

    log("CL-Networking: reading %d items for inventory %d", its, invID)

    

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

        -- Read deletions
        if net.ReadBool() then
            local dels = net.ReadUInt(16)

            log("CL-Networking: reading %d deletions", dels)

            for i=1, dels do
                local uid = net.ReadUInt(max_uid)
                local del_it = inv:DeleteItem(uid, true)
                log("   successfully deleted item")
                Inventory:Emit("ItemRemoved", inv, del_it)
            end
        end
        log("finished with deletions")
        -- Read slot moves

        if net.ReadBool() then
            local moves = net.ReadUInt(16)

            log("CL-Networking: reading %d moves", moves)

            for i=1, moves do
                local uid = net.ReadUInt(max_uid)
                print("max uid:", max_uid)
                local slot = net.ReadUInt(bit.GetLen(inv.MaxItems))
                log("   moving item %s into slot %s", uid, slot)
                local item = inv:GetItem(uid)
                item:SetSlot(slot)
                --log("   successfully moved item %s into slot %s", uid, slot)
                --Inventory:Emit("ItemChanged", inv, item)
                Inventory:Emit("ItemMoved", inv, item)
            end
        end
        log("finished with slot moves")
        -- Read inventory moves

        if net.ReadBool() then
            local moves = net.ReadUInt(16)

            log("CL-Networking: reading %d moves", moves)

            for i=1, moves do
                local uid = net.ReadUInt(max_uid)
                local where = net.ReadUInt(8)
                local newinv = invtbl[where]
                log("   moving item %s into inventory %s", uid, inv)
                local item = inv:GetItem(uid)

                if item then
                    --if there was no item that means we already predicted the removal somewhere
                    inv:RemoveItem(item, true)
                    item:SetInventory(newinv)
                end
            end
        end
        log("finished with moves")
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

        if v.MultipleInstances then
            invs_table[k] = v
        else
            invs_table[v.NetworkID] = v
        end
    end

    for i=1, invs do
        nw.ReadInventoryContents(invs_table, type)
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
    dat = von.deserialize(dat)
    local conv = Inventory.IDConversion

    for iid, iname in pairs(dat) do
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

function invnet:WriteInventory(inv, key)
    print("writeinventory", inv)
    self:WriteEntity( (inv:GetOwner()) )
    self:WriteUInt(inv.NetworkID, 16)

    if inv.MultipleInstances then
        if not key then
            local ow = inv:GetOwner()
            if not IsValid(ow) then errorf("Tried to write an inventory with multiple instances but without an owner! %s", inv) return end
            for k,v in pairs(inv:GetOwner().Inventory) do
                if v == inv then
                    key = k
                    break
                end
            end
            if not key then errorf("Couldn't find key for inventory: %s", inv) return end
        end

        self:WriteUInt(key, 16)
    end

    self.CurrentInventory = inv

    return self
end

function invnet:WriteItem(it, ignore)
    if not self.CurrentInventory or not self.CurrentInventory:HasItem(it) and not ignore then 
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