--
setfenv(0, _G)
local nw = Inventory.Networking or {InventoryIDs = {}}
Inventory.Networking = nw
nw.Verbose = true

local realLog = Inventory.Log

log = function(...)
    if not Inventory.Networking.Verbose then return end
    realLog(...)
end

function nw.ReadHeader()
    local max_uid, max_id = net.ReadUInt(5), net.ReadUInt(5)
    return max_uid, max_id
end

function nw.ReadItem(uid_sz, iid_sz)
    if not uid_sz or not iid_sz then
        uid_sz, iid_sz = nw.ReadHeader()
    end

    local uid, iid = net.ReadUInt(uid_sz), net.ReadUInt(iid_sz)
    local has_slot = net.ReadBool()
    if has_slot then
        errorf("NW-Read item (uid: %s, iid: %s) has a slot, meaning it's not inventory-less!", uid, iid)
        return
    end

    item = Inventory.ReconstructItem(uid, iid)
    item:ReadNetworkedVars()
    Inventory.ItemPool[uid] = item
    return item
end

function nw.ReadInventoryItem(uid_sz, iid_sz, slot_sz, inventory)
    local uid, iid = net.ReadUInt(uid_sz), net.ReadUInt(iid_sz)
    local has_slot = net.ReadBool()

    slot_sz = slot_sz or (inventory and inventory.MaxItems and bit.GetLen(inventory.MaxItems))
    local slot = has_slot and slot_sz and net.ReadUInt(slot_sz)

    local item

    if inventory then
        item = inventory:HasItem(uid)
        log("       Read item UID: %s (sz: %d); IID: %s (sz: %d); Slot: %s (sz: %d)",
            uid, uid_sz, iid, iid_sz, slot, slot_sz)
    end

    if not item then
        item = Inventory.ReconstructItem(uid, iid, inventory)
    end

    if slot then
        item:SetSlot(slot)
    end

    if inventory then
        inventory:AddItem(item, true)
    end

    item:ReadNetworkedVars()
    --item:SetInventory(inventory)

    Inventory.ItemPool[uid] = item
    return item
end

function nw.ShouldAction(itm, act, tok, dat, dat2)
    local acts = itm:GetCommitedActions(act)

    if acts[tok] then
        if act == "CrossInv" then
            local svSez = ("%p:%s"):format(dat, dat2)
            print(svSez, acts[tok])
            if svSez ~= acts[tok] then
                print("desync! ^", tok, dat)
                return true
            end

            return false
        elseif acts[tok] == dat then
            print(act, acts[tok], dat)
            return false
        end
    else
        --print("!! no actions for", act, tok)
    end

    return true
end

function nw.ReadInventoryContents(invtbl, typ, tok)
    local max_uid, max_id = nw.ReadHeader()

    local invID = net.ReadUInt(16)

    local inv

    for k, baseinv in pairs(Inventory.Inventories) do
        if baseinv.NetworkID == invID then
            if baseinv.MultipleInstances then
                local key = net.ReadUInt(16)
                inv = invtbl[key]
            else
                inv = invtbl[baseinv.NetworkID]
            end
            break
        end
    end

    if not inv then errorf("Didn't find inventory with NetworkID %s!", invID) end

    inv.ReadingNetwork = true

    if typ == INV_NETWORK_FULLUPDATE then
        log("!!!!!DROPPING INVENTORY!!!!!")
        inv:Reset()
    end

    local its = net.ReadUInt(16)

    log("CL-NW: reading %d items for inventory %d", its, invID)

    local slot_size = inv.MaxItems and bit.GetLen(inv.MaxItems)

    for i=1, its do
        log("   reading item #%d", i)
        local it = nw.ReadInventoryItem(max_uid, max_id, slot_size, inv)
        --inv:AddItem(it)
        log("   successfully added item")
        Inventory:Emit("ItemAdded", inv, it)
    end

    if typ == INV_NETWORK_UPDATE then

        -- Read deletions
        if net.ReadBool() then
            local dels = net.ReadUInt(16)

            log("CL-NW: reading %d deletions", dels)

            for i=1, dels do
                local uid = net.ReadUInt(max_uid)
                -- should this action be token-confirmed?
                local del_it = inv:DeleteItem(uid, true)
                --log("   successfully deleted item %d", uid)
                Inventory:Emit("ItemRemoved", inv, del_it)
            end
        end
        log("finished with deletions")

        -- read items that were moved into this inventory
        if net.ReadBool() then
            local moves = net.ReadUInt(16)

            log("CL-NW: reading %d cross-inv moves", moves)

            for i=1, moves do
                local uid = net.ReadUInt(max_uid)
                local slot = net.ReadUInt(bit.GetLen(inv.MaxItems)) --net.ReadUInt(8)
                local newinv = inv--invtbl[where]
                log("   crossmoving item %s into inventory %s", uid, newinv)
                local item = Inventory.ItemPool[uid] --inv:GetItem(uid)

                if item and nw.ShouldAction(item, "CrossInv", tok, newinv, slot) then
                    --if there was no item that means we already predicted the removal somewhere
                    log("removing item from", item:GetInventory())
                    item:GetInventory():RemoveItem(item, nil, true)

                    item:SetSlot(slot)
                    newinv:AddItem(item, true)
                else
                    log("   !! we weren't aware of that item ^^^", uid, newinv)
                end
            end
        end
        log("finished with moves")

        -- Read slot moves
        if net.ReadBool() then
            local moves = net.ReadUInt(16)

            log("CL-NW: reading %d moves", moves)

            for i=1, moves do
                local uid = net.ReadUInt(max_uid)
                local slot = net.ReadUInt(bit.GetLen(inv.MaxItems))
                log("   moving item %s into slot %s", uid, slot)

                local item = inv:GetItem(uid)

                if not item then
                    log("wtf is that item!!! %s", uid)
                end

                if item and nw.ShouldAction(item, "Move", tok, slot) then
                    item:SetSlot(slot)
                    --log("   successfully moved item %s into slot %s", uid, slot)
                    --Inventory:Emit("ItemChanged", inv, item)
                    Inventory:Emit("ItemMoved", inv, item)
                end
            end
        end
        log("finished with slot moves")


    end

    inv.ReadingNetwork = false
    inv:Emit("Change")
end

function nw.Resync()
    nw.PerformAction(INV_ACTION_RESYNC)
end

function nw.ReadUpdate(len, type)
    local invs = net.ReadUInt(8)
    local ent = net.ReadEntity()
    local has_tok = net.ReadBool()
    local tok
    if has_tok then
        tok = net.ReadUInt(16)
    end

    realLog("CL-NW: Update: Received %d inventories for %s; packet length is %d bytes", invs, ent, len / 8)

    local invs_table = {} --map out all the entity's inventories into {[nwID] = obj} pairs

    for k,v in pairs(ent.Inventory) do
        if v.MultipleInstances then
            invs_table[k] = v
        else
            invs_table[v.NetworkID] = v
        end
    end

    for i=1, invs do
        nw.ReadInventoryContents(invs_table, type, tok)
    end
end


function nw.ReadNet(len)
    --realLog("CL-NW: ReadNet: Received inventory update")
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

    hook.Run("InventoryIDReceived", conv.ToName, conv.ToID)
    log("CL-NW: Received & parsed inventory constants")
end


net.Receive("InventoryConstants", nw.ReadConstants)

local invnet = netstack:extend()
local log = Inventory.Log

function invnet:WriteInventory(inv, key)
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
        net.WriteUInt(Inventory.GetToken(), 16)
        if ns then net.WriteNetStack(ns) end
    net.SendToServer()
end

function nw.DeleteItem(it)
    local ns = Inventory.Networking.Netstack()
    ns:WriteInventory(it:GetInventory())
    ns:WriteItem(it)
    Inventory.Networking.PerformAction(INV_ACTION_DELETE, ns)
end