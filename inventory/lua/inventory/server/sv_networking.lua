util.AddNetworkString("Inventory")
util.AddNetworkString("InventoryConstants")

local PLAYER = FindMetaTable("Player")

Inventory.Networking = Inventory.Networking or {InventoryIDs = {}}
local nw = Inventory.Networking

local invnet = netstack:extend()
_G.invnet = invnet

local log = Inventory.Log

function invnet:Initialize(uid, iid)
    self.MaxUIDLen = (uid and bit.GetLen(uid)) or 32
    self.MaxIDLen = (iid  and bit.GetLen(iid)) or 32

    self.MaxUID = uid or 4294967296
    self.MaxID = iid or 4294967296

    self:WriteUInt(self.MaxUIDLen, 5)  --maximum bit size of a  UID in the queue
    self:WriteUInt(self.MaxIDLen, 5)   --maximum bit size of an IID in the queue
end

function invnet:WriteIDs(it)
    local uid, iid = it:GetUID(), it:GetIID()

    if uid > self.MaxUID then errorf("UID out of initialized range! (attempted to write: %d ; max. was: %d)", uid, self.MaxUID) end
    if iid > self.MaxID then errorf("IID out of initialized range! (attempted to write: %d ; max. was: %d)", iid, self.MaxID) end

    self:WriteUInt(uid, self.MaxUIDLen)
    self:WriteUInt(iid, self.MaxIDLen)
end

function invnet:WriteSlot(it)
    local len = it:GetInventory().MaxItems
    if len then
        len = bit.GetLen(len)
        self:WriteUInt(it:GetSlot(), len)
    end
end

function nw.NetworkItemNames(ply)
    log("Netwokring constants for %s", ply)

    local dat = von.serialize(Inventory.IDConversion.ToName)
    local comp = util.Compress(dat)
    local needs_comp = false

    if #comp < #dat then
        needs_comp = true
        dat = comp
    end

    net.Start("InventoryConstants")
        net.WriteUInt(#dat, 16)
        net.WriteBool(needs_comp)
        net.WriteData(dat, #dat)
    net.Send(ply)

    log("SV-NW: Sent inventory constants to %s", IsPlayer(ply) and ply:Nick() or (#ply .. " players"))
end

timer.Simple(1, function()
    if Inventory.MySQL.IDsReceived then
        nw.NetworkItemNames(player.GetAll())
    else
        hook.Once("InventoryItemIDsReceived", "NetworkConstants", function()
            nw.NetworkItemNames(player.GetAll())
        end)
    end
end)

function nw.NetStack(uid, iid)
    local ns = invnet:new(uid, iid)
    return ns
end

function nw.SendNetStack(ns, ply)
    net.Start("Inventory")
        net.WriteNetStack(ns)
    net.Send(ply)
end

function nw.SendNetStacks(nses, ply)
    net.Start("Inventory")
        for k,v in ipairs(nses) do
            net.WriteNetStack(v)
        end
    net.Send(ply)
end

function nw.NetworkInventory(ply, inv, just_return) --mark 'just_return' as true for this function to just return an invnet (netstack) object
    if inv and not inv.NetworkID then errorf("Cannot send inventory %q as it doesn't have a network ID!", inv.Name) return end

    if inv then
        
        local ns = inv:SerializeItems()

        if just_return then
            return ns
        else
            nw.SendNetStack(ns)
        end
    else --no inventory was specified; let's assume network the entire inventory of player
        local stacks = {}

        for k,v in pairs(ply.Inventory) do --recursively network every inventory
            stacks[#stacks + 1] = nw.NetworkInventory(ply, v, true)
        end

        local header = netstack:new()
        header:WriteUInt(#stacks, 8)        --write amount of inventories we networked
        header:WriteEntity(ply)             --write the player whose inventories we're networking

        table.insert(stacks, 1, header) 

        if just_return then
            return stacks
        else
            nw.SendNetStacks(stacks, ply)
        end
    end
end

PLAYER.NetworkInventory = nw.NetworkInventory
PLAYER.NI = nw.NetworkInventory

