include("shared.lua")

local me = {}
ENT.ContextInteractable = true 

function ENT:Initialize()

end

function ENT:DrawDisplay()

end


function ENT:InteractItem(item, slot)

end

function ENT:ContextInteractItem(item, slot)

end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()

end

function ENT:OnOpenRefine(ref)

end

function ENT:OnCloseRefine(ref)

end

function ENT:OpenMenu()
	if IsValid(self.Frame) then return end

	local inv = Inventory.Panels.CreateInventory(LocalPlayer().Inventory.Backpack)
	inv:SetTall(350)
	inv:CenterVertical()

	local ref = vgui.Create("NavFrame")
	self.Frame = ref
	ref:SetSize(450, 350)
	ref:MakePopup()
	ref:SetPos( ScrW() / 2 - (450 + 8 + inv:GetWide()) / 2,
				ScrH() / 2 - 350 / 2)
	ref.Shadow = {}
	ref:SetRetractedSize(40)
	ref:SetExpandedSize(200)

	inv:Bond(ref)
	ref:Bond(inv)

	inv:MoveRightOf(ref, 8)

	local refTab = ref:AddTab("Refine ores", function() self:OnOpenRefine(ref) end, function() self:OnCloseRefine(ref) end)
	refTab:SetTall(60)
	refTab:Select(true)
end

net.Receive("OreRefinery", function()
	local ent = net.ReadEntity()

	ent:OpenMenu()
end)
