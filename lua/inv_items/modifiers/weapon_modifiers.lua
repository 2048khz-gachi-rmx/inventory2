--

local curMod
local function make(nm)
	local mod = Inventory.BaseModifier:new(nm)
	curMod = mod

	return mod
end


local numCol, notNumCol = Color(100, 250, 100), Color(80, 100, 80)
local textCol = Color(130, 130, 130)

make("Blazing")
	:SetMaxTier(4)
	:SetRetired(true)

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

-- does nothing; only for compat
make("Crippling")
	:SetMaxTier(3)
	:SetRetired(true)


make("Vampiric")
	:SetMaxTier(3)
	:Hook("PostEntityTakeDamage", function(self, ent, dmg)
		local str = self:GetTierStrength(self:GetTier())
		if not str then return end
		str = str / 100

		local atk = dmg:GetAttacker()
		if not IsPlayer(atk) then return end

		local regen = dmg:GetDamage() * str
		atk:AddHealth(regen)
	end)
	:SetTierCalc(function(self, tier)
		return tier * 10
	end)

function curMod:GenerateMarkup(it, mup, tier)
	local mod = mup:AddPiece()
	mod:SetAlignment(1)
	mod.Font = "MRB28"

	local tx = mod:AddText("Vampiric")
	mod:SetColor(Color(80, 220, 95))

	local desc = mup:AddPiece()
	desc.Font = "OS16"
	desc:DockMargin(8, 0, 0, 0)
	desc:SetColor(textCol)
	desc:SetAlignment(1)

	local tx = desc:AddText("Steal ")

	for i=1, self:GetMaxTier() do
		local tx2 = desc:AddText(tostring(self:GetTierStrength(i)))
		tx2.color = i == tier and numCol or notNumCol

		if i ~= self:GetMaxTier() then
			local sep = desc:AddText("/")
			sep.color = notNumCol
		end
	end
	desc:AddText("% of damage dealt as health.")

	local nw = desc:RewrapWidth(350)
	mup:SetWide(math.max(mup:GetWide(), nw))
end


local el; el = make("Elastic")
	:SetMaxTier(3)
	:Hook("SetupMove", function(self, ply, mv, cmd)
		if not bit.Has( mv:GetButtons(), IN_JUMP, IN_SPEED ) or
			bit.Has( mv:GetOldButtons(), IN_JUMP ) or
			not ply:OnGround() then
			self._Jumped = false
			return
		end

		self._Jumped = true
	end)
	:Hook("Move", function(self, ply, mv, dmg)
		if not self._Jumped then return end

		local str = self:GetTierStrength(self:GetTier()) / el.SpeedDiv
		if not str then return end

		--[[local forward = mv:GetVelocity()
		forward.z = 0
		forward:Normalize()]]

		local forward = mv:GetAngles()
		forward.p = 0
		forward = forward:Forward()

		-- Reverse it if the player is running backwards
		if mv:GetVelocity():Dot(forward) < 0 then
			str = -str
		end

		-- Apply the speed boost
		mv:SetVelocity(forward * str + mv:GetVelocity())
	end)
	:Hook("FinishMove", function(self, ply, mv)
		mv:SetMaxSpeed(mv:GetMaxSpeed() + self:GetTierStrength(self:GetTier()) / el.SpeedDiv)
	end)

	:SetTierCalc(function(self, tier)
		return 10 * tier
	end)

el.SpeedDiv = 0.1

function curMod:GenerateMarkup(it, mup, tier)
	local mod = mup:AddPiece()
	mod:SetAlignment(1)
	mod.Font = "BSB28"

	local tx = mod:AddText("Elastic")
	mod:SetColor(Color(220, 220, 220))

	local desc = mup:AddPiece()
	desc.Font = "OS16"
	desc:DockMargin(8, 0, 0, 0)
	desc:SetColor(textCol)
	desc:SetAlignment(1)
	local tx = desc:AddText("Jumping while sprinting will propel you ")

	for i=1, self:GetMaxTier() do
		local tx2 = desc:AddText(tostring(self:GetTierStrength(i)))
		tx2.color = i == tier and numCol or notNumCol

		if i ~= self:GetMaxTier() then
			local sep = desc:AddText("/")
			sep.color = notNumCol
		end
	end

	desc:AddText(" meters forward.")

	local nw = desc:RewrapWidth(250)
	mup:SetWide(math.max(mup:GetWide(), nw))
end