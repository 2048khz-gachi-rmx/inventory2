local numCol, notNumCol, textCol = unpack(Inventory.Modifiers.DescColors)

local el; el = Inventory.BaseModifier:new("Elastic")
	:SetMaxTier(3)
	:SetMinBPTier(3)
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

local recipes = {
	{"thruster_t1", 2},
	{"thruster_t2", 2},
	{"thruster_t2", 4},
}
el  :On("AlterRecipe", "a", function(self, itm, rec, tier)
		local itName = recipes[tier][1]
		rec[itName] = (rec[itName] or 0) + recipes[tier][2]
	end)

el.SpeedDiv = 0.1

function el:GenerateMarkup(it, mup, tier)
	local mod = mup:AddPiece()
	mod:SetAlignment(1)
	mod.Font = "BSB24"

	local tx = mod:AddText("Propulsion "  .. string.ToRoman(tier))
	mod:SetColor(Color(110, 160, 240))

	local desc = mup:AddPiece()
	desc.Font = "OS16"
	desc:DockMargin(8, 0, 8, 0)
	desc:SetColor(textCol)
	desc:SetAlignment(1)
	local tx = desc:AddText("Jumping while sprinting will propel you ")

	for i=1, self:GetMaxTier() do
		local tx2 = desc:AddText(tostring(self:GetTierStrength(i)) .. "m")
		tx2.color = i == tier and numCol or notNumCol

		if i ~= self:GetMaxTier() then
			local sep = desc:AddText("/")
			sep.color = notNumCol
		end
	end

	desc:AddText(" forward.")
end