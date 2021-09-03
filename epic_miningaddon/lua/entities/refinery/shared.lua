ENT.Type = "anim"
ENT.Base = "bw_base_electronics"
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.PrintName = "Refinery or smth"

ENT.MaxQueues = 7
ENT.OutputSlots = 3
ENT.InventoryUseOwnership = false

ENT.PowerRequired = 25

function ENT:SHInit()
	self.Inventory = {Inventory.Inventories.Entity:new(self), Inventory.Inventories.Entity:new(self)}

	self.OreInput = self.Inventory[1] --shortcuts
	self.OreInput.MaxItems = self.MaxQueues

	self.OreOutput = self.Inventory[2]
	self.OreOutput.MaxItems = self.OutputSlots

	self.Status = Networkable(("Refinery:%d"):format(self:EntIndex())):Bond(self)

	self.OreOutput.ActionCanCrossInventoryFrom = true
	self.OreOutput.ActionCanCrossInventoryTo = false

	self.OreInput.ActionCanCrossInventoryFrom = false
	self.OreInput.ActionCanCrossInventoryTo = true

	self.OreInput:On("CanAddItem", "OresOnly", function(self, it)
		local can = it.AllowedRefineryInsert
		it.AllowedRefineryInsert = nil
		return can or it.IsOre == true
	end)

	self.OreInput:On("CanMoveItem", "OresOnly", function(self, it)
		return it.IsOre == true
	end)

	self.BaseClass.SHInit(self)
end