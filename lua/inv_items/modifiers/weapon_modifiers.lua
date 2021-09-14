--

local curMod
local function make(nm)
	local mod = Inventory.Modifier:new(nm)
	curMod = mod

	return mod
end



make("Blazing")
	:SetMaxTier(4)

function curMod:GenerateMarkup(it, mup, tier)
	local mod = mup:AddPiece()
	mod:SetAlignment(1)
	mod:AddText("Blazing")
	mod.IgnoreVisibility = true
	local bcol = Color(180, 150, 60)
	mod:SetColor(bcol)

	mod:On("Think", function()
		bcol.r = 210 + math.abs(math.sin(CurTime() * 2.3) * 40)
		bcol.g = 120 + math.abs(math.sin(CurTime() * 1.7) * 20)
	end)
	local desc = mup:AddPiece()
	desc.Font = "OS16"
	desc:DockMargin(4, 0, 0, 0)
	desc:SetColor(Color(180, 150, 60))
	desc:SetAlignment(1)
	local tx = desc:AddText("BRrrrrrrrrrrrt and you're ~ablaze~")
	desc.IgnoreVisibility = true

	local nw = desc:RewrapWidth(200)
	mup:SetWide(math.max(mup:GetWide(), nw))
end


make("Crippling")
	:SetMaxTier(3)

function curMod:GenerateMarkup(it, mup, tier)
	local mod = mup:AddPiece()
	mod:SetAlignment(1)
	mod.Font = "OS24"

	local t = mod:AddTag(MarkupTags("rotate", -10, 0))
	local tx = mod:AddText("Crip")

	mod:EndTag(t)
	mod:AddTag(MarkupTags("rotate", 10, 0))

	tx = mod:AddText(" pling")

	mod.IgnoreVisibility = true

	mod:On("RecalculateHeight", "RotationCorrection", function(self, buf, maxh)
		surface.SetFont(mod.Font)
		local tw, th = surface.GetTextSize("pling")
		local bw, bh = math.AARectSize(tw, th, 10)
		return math.ceil(bh)
	end)

	local desc = mup:AddPiece()
	desc.Font = "OS16"
	desc:DockMargin(8, 0, 0, 0)
	desc:SetColor(Color(130, 130, 130))
	desc:SetAlignment(1)
	local tx = desc:AddText("[NYI] Each shot applies a stacking ???% decrease to your victim's movement speed for ???s.")
	tx.WrapData = { AllowDashing = false }
	desc.IgnoreVisibility = true

	local nw = desc:RewrapWidth(250)
	mup:SetWide(math.max(mup:GetWide(), nw))
end
