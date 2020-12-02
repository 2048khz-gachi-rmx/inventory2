local gen = Inventory.GetClass("item_meta", "generic_item")
local mod = Inventory.ItemObjects.EntityModule or gen:Extend("EntityModule")

mod.IsModule = true

BaseItemAccessor(gen, "IsModule", "Module")
BaseItemAccessor(mod, "Compatibles", "Compatibles")

mod:On("CanCrossMove", "CompatOnly", function(self, inv1, inv2, slot)

	local listeners = inv2:GetListeners("CanInstallModule")
	local any_listeners = listeners and #listeners >= 0

	-- if we failed the emit check, we bail
	if inv2:Emit("CanInstallModule", self, inv1, slot) == false then
		print("emitter returned no")
		return false
	end

	local predefCompats = self:GetCompatibles()
	local ent = inv2:GetEntityOwner()
	ent = ent:IsValid() and ent or nil

	if not ent then error("Inventory EntityOwner invalid!") return end


	if predefCompats and table.Count(predefCompats) > 0 then
		local ok = false

		if predefCompats.__inheritsFrom and predefCompats.__inheritsFrom == ent.Base then ok = true end
		if predefCompats[ent:GetClass()] or table.HasValue(predefCompats, ent:GetClass()) then ok = true end

		if not ok then return false end
	end

	-- if there's no listeners nor predefined compatibles, and its an ent inv,
	--then we bail 'cause that inventory is probably not supposed to accept modules

	if inv2.IsEntityInventory and not any_listeners and
		not (predefCompats and table.Count(predefCompats) > 0) then
		print("no listeners, no compats")
		return false
	end

	print("can install")
end)

mod:Register()