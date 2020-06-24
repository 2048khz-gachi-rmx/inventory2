function Inventory.CanEquipInSlot(it, slotid)
	local slot = istable(slotid) and slotid or Inventory.EquipmentSlots[slotid]
	if not slot then return false, ("No Equipment slot exists @ ID %s"):format(slotid) end

	local slotName = slot.slot --requested slot
	local should = it:GetEquipSlot() --possible slot to go into, if one is set (weapons can be cross-slot)

	if isstring(should) and should ~= slotName then 
		return false, ("BaseItem slot doesn't match requested slot: %s vs. %q"):format(should, slotName)
	end

	if istable(should) and not table.HasValue(should, slotname) then 
		return false, ("BaseItem possible slots don't match requested slot: {%s} vs. %q"):format(table.concat(should, ", "), slotName)
	end

	return true
end