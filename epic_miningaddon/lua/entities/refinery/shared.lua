ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.RenderGroup = RENDERGROUP_BOTH

ENT.Spawnable = false
ENT.AdminSpawnable = false

ENT.PrintName = "Refinery or smth"

ENT.MaxQueues = 7
ENT.OutputSlots = 3
ENT.InventoryUseOwnership = false

function ENT:SetupDataTables()

	self:NetworkVar("Bool", 0, "Working")
	self:NetworkVar("String", 0, "Queues")
	self:NetworkVar("Int", 0, "MaxQueues")
	if SERVER then
		self:SetWorking(false)
		self:SetMaxQueues(4)
		self:SetQueues("2222")
	end

end

function ENT:SHInit()
	self.Inventory = {Inventory.Inventories.Entity:new(self), Inventory.Inventories.Entity:new(self)}

	self.OreInput = self.Inventory[1] --shortcuts
	self.OreInput.MaxItems = self.MaxQueues

	self.OreOutput = self.Inventory[2]
	self.OreOutput.MaxItems = self.OutputSlots

	self.Status = Networkable(("Refinery:%d"):format(self:EntIndex())):Bond(self)


	self.OreInput:On("CanAddItem", "OresOnly", function(self, it)
		return it.IsOre == true
	end)

	self.OreInput:On("CanMoveItem", "OresOnly", function(self, it)
		return it.IsOre == true
	end)

end