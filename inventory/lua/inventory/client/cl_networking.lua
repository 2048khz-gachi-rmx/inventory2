--

local nw = Inventory.Networking or {InventoryIDs = {}}
Inventory.Networking = nw

local log = Inventory.Log

function nw.ReadHeader()
    local max_uid, max_id = net.ReadUInt(5), net.ReadUInt(5)
    return max_uid, max_id
end

function nw.ReadItem(uid_sz, iid_sz, slot_sz)
    local uid, iid = net.ReadUInt(uid_sz), net.ReadUInt(iid_sz)
    local slot = slot_sz and net.ReadUInt(slot_sz)

    local meta = Inventory.Util.GetMeta(iid)
    local item = meta:new(uid, iid)

    if slot then item:SetSlot(slot) end

    log("       Read item UID: %s; IID: %s; Slot: %s", uid, iid, slot)
    return item
end

function nw.ReadInventory(invtbl)
    local max_uid, max_id = nw.ReadHeader()
    local invID = net.ReadUInt(16)
    local its = net.ReadUInt(16)

    log("CL-Networking: reading %d items for inventory %d", its, invID)

    
    local inv = invtbl[invID] or errorf("Could not find Inventory with ID %d in that entity!!", invID)
    print("inv is", inv, inv.Slots, inv.Items, inv.Owner)
    AAA = invtbl
    local slot_size = inv.MaxItems and bit.GetLen(inv.MaxItems)

    for i2=1, its do
        log("   reading item #%d", i2)
        local it = nw.ReadItem(max_uid, max_id, slot_size)
        inv:AddItem(it)
        log("   successfully added item")
    end

    print("\n")
end



function nw.ReadNet(len)
    local invs = net.ReadUInt(8) --amount of inventories
    local ent = net.ReadEntity()
    
    log("CL-NW: Received %d inventories for %s; packet length is %d", invs, ent, len)

    local invs_table = {} --map out all the entity's inventories into {[nwID] = obj} pairs

    for k,v in pairs(ent.Inventory) do
        invs_table[v.NetworkID] = v
    end

    for i=1, invs do
        nw.ReadInventory(invs_table)
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
    print("deserializing", dat)
    dat = von.deserialize(dat)

    local conv = Inventory.IDConversion

    for iid, iname in ipairs(dat) do
        conv.ToName[iid] = iname
        conv.ToID[iname] = iid
    end

    hook.Run("InventoryIDReceived", conv.ToName, conv.ToID)
    log("CL-NW: Received & parsed inventory constants")
end


net.Receive("InventoryConstants", nw.ReadConstants)