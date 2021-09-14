if Inventory.ItemsLoading then return end

Inventory.ItemsLoading = true
FInc.Recursive("inv_items/*", _SH, nil, FInc.RealmResolver():SetDefault(true))
Inventory.ItemsLoading = false