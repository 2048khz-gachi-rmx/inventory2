local cards = {}

table.insert(cards,
	Inventory.BaseItemObjects.Generic("card1")
		:SetName("Level 1 Access Keycard")
		:SetModel("models/labskeycards/normalkeycard.mdl")

		:SetCamPos( Vector(54.7, -0.7, 67.1) )
		:SetLookAng( Angle(50.8, -180.7, 0.0) )
		:SetFOV( 3.5 )

		:SetCountable(true)
		:SetMaxStack(3)
		:SetBaseTransferCost(150000)

		:SetRarity("common")
)

table.insert(cards,
	Inventory.BaseItemObjects.Generic("card2")
		:SetName("Level 2 Access Keycard")
		:SetModel("models/labskeycards/greenkeycard.mdl")

		:SetCamPos( Vector(54.7, -0.7, 67.1) )
		:SetLookAng( Angle(50.8, -180.7, 0.0) )
		:SetFOV( 3.5 )

		:SetCountable(true)
		:SetMaxStack(3)
		:SetBaseTransferCost(150000)

		:SetRarity("uncommon")
)

table.insert(cards,
	Inventory.BaseItemObjects.Generic("card3")
		:SetName("Level 3 Access Keycard")
		:SetModel("models/labskeycards/bluekeycard.mdl")

		:SetCamPos( Vector(54.7, -0.7, 67.1) )
		:SetLookAng( Angle(50.8, -180.7, 0.0) )
		:SetFOV( 3.5 )

		:SetCountable(true)
		:SetMaxStack(3)
		:SetBaseTransferCost(150000)

		:SetRarity("rare")
)

for k,v in pairs(cards) do
	v.IsKeyCard = true
	local lvl = v:GetItemName() and tonumber(v:GetItemName():match("%d+$"))
	v.AccessLevel = lvl or k

	if not lvl then
		errorNHf("failed to resolve card access level: %s (using: %d)", v:GetItemName(), v.AccessLevel)
	end
end