if Inventory.ItemsLoading then return end

Inventory.ItemsLoading = true
FInc.Recursive("inv_items/rarities_ext/*", _SH, nil, FInc.RealmResolver():SetDefault(true))
FInc.Recursive("inv_items/*", _SH, nil, FInc.RealmResolver():SetDefault(true):SetVerbose())
Inventory.ItemsLoading = false