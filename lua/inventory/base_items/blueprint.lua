local gen = Inventory.GetClass("base_items", "unique")
local bp = gen:ExtendItemClass("Blueprint", "Blueprint")

bp:Register()
bp.BaseTransferCost = 150000

include("blueprint_" .. Rlm(true) .. "_ext.lua")