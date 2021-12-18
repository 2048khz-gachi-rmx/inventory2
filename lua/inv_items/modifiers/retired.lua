
local function retMark(self, it, mup, tier)
	local mod = mup:AddPiece()
	mod:SetAlignment(1)
	mod:AddText(self:GetName())

	local bcol = Color(200, 100, 100)
	mod:SetColor(bcol)

	mod:On("Think", function()
		bcol.r = 210 + math.abs(math.sin(CurTime() * 2.3) * 40)
	end)

	local desc = mup:AddPiece()
	desc.Font = "OS24"
	desc:DockMargin(8, 0, 8, 0)
	desc:SetColor(Color(180, 150, 60))
	desc:SetAlignment(1)

	desc:AddTag(MarkupTag("chartranslate", 0, function(char, i)
		if not i then return end
		return math.sin(CurTime() * 3 + i / 4) * 3
	end))

	local tx = desc:AddText("Retired modifier")
	desc.IgnoreVisibility = true

	desc:AddTag(MarkupTag("emote", "MikuBaka", 32, 32))
end

local curMod
local function make(nm)
	local mod = Inventory.BaseModifier:new(nm)
	mod:SetRetired(true)
	curMod = mod
	curMod.GenerateMarkup = retMark

	return mod
end


make("Blazing")
	:SetMaxTier(4)

make("Crippling")
	:SetMaxTier(3)