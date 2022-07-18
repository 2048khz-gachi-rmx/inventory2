local gen = Inventory.GetClass("base_items", "generic_item")
local mod = gen:ExtendItemClass("EntityModule", "EntityModule")

mod.IsModule = true

ChainAccessor(mod, "Compatibles", "Compatibles")
ChainAccessor(mod, "Compatibles", "Compatible")

mod:Register()

function Inventory.IsModule(w)
	return istable(w) and w.IsModule
end

mod:NetworkVar("Bool", "Installed")