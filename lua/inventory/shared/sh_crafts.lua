--

Inventory.Crafts = Inventory.Crafts or {}

local recipe = Emitter:callable()
function recipe:Initialize(itemName)
	self.Name = itemName
	self.Recipe = {}
end

ChainAccessor(recipe, "Name", "Name")
ChainAccessor(recipe, "Recipe", "Recipe") -- yeees

function recipe:AddRequirement(id, dat)
	local t = {
		id = id
	}

	self.Recipe[#self.Recipe + 1] = t

	for k,v in pairs(dat) do
		t[k] = v
	end
end

function Inventory.AddCraft(name)
	local rec = recipe:new(name)
	Inventory.Crafts[name] = rec

	return rec
end