
local gen = Inventory.GetClass("base_items", "unique")
local eq = gen:ExtendItemClass("Equipment", "Equippable")

eq.IsEquippable = true

ChainAccessor(eq, "IsEquippable", "Equippable")
ChainAccessor(eq, "EquipSlot", "EquipSlot")

function eq:SetEquipSlot(sl)
	local class = self.BaseName:lower()

	for k,v in ipairs(Inventory.EquipmentSlots) do
		if v.slot:lower() == sl then

			if v.type and v.type:lower() ~= class then
				--failure: slot was found, but its' type doesn't accept this baseclass
				errorf("Equipment slot %q only accepts type %q, got %q instead.", v.slot, v.type, class)
			end

			--success:
			self.EquipSlot = sl
			return
		end
	end

	--failure: didn't find this slot
	errorf("Didn't find Equipment slot: %q", sl)

end

eq:Register()
