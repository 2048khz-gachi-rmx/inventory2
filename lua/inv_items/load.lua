if Inventory.ItemsLoading then return end

Inventory.ItemsLoading = true
FInc.Recursive("inv_items/rarities_ext/*", _SH, FInc.RealmResolver():SetDefault(true))
FInc.Recursive("inv_items/*", _SH, FInc.RealmResolver():SetDefault(true))
Inventory.ItemsLoading = false