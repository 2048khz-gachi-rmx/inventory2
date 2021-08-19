StartTool("OreMark")

	local nw = Networkable("Orepositions")

	nw:On("ReadChangeValue", 1, function(self, k)
		if not IsPlayer(k) and k ~= "Positions" then print("Hell no", k) return end
		local isPos = k == "Positions"

		local amt = net.ReadUInt(isPos and 16 or 8)

		local poses = self:Get(k)

		if not istable(poses) then
			self:Set(k, {})
			poses = {}
		end

		for i=1, amt do
			local k = net.ReadUInt(isPos and 16 or 8)
			local exists = net.ReadBool()

			if not exists then
				poses[k] = nil
			else
				local vec = net.ReadVector()
				poses[k] = vec
			end
		end


		return poses
	end)

	local v1 = Vector(4, 4, 4)
	local v2 = -v1

	local visv1
	local visv2

	local function closestIntersection(t, ep, fw)
		local hit, hitDist, key = nil, math.huge
		if not istable(t) then return end

		for k, v in pairs(t) do

			local vechit = util.IntersectRayWithOBB(ep, fw, v, angle_zero, v2, v1)
			if vechit then
				local dist = vechit:DistToSqr(v)

				if hitDist > dist then
					hit = v
					key = k
					hitDist = dist
				end
			end
		end

		return hit, key
	end

	function TOOL:LeftClick(tr)
		return true
	end

	function TOOL:Allowed()
		return self:GetOwner():IsSuperAdmin()
	end

	function TOOL:RightClick(tr)
		return true
	end

	function TOOL:Reload()

	end

	TOOL.IsOreMark = true
EndTool()


local curCol = Colors.Golden:Copy()
local bufFrac = WeakTable(nil, "k")
local an = Animatable("Vectahs")

hook.Add("PostDrawTranslucentRenderables", "OresRender", function(a, b)
	if a or b then return end

	if not LocalPlayer():IsSuperAdmin() then print("Not sa") return end

	local tool = LocalPlayer():GetTool()
	if not tool or not tool.IsOreMark then return end

	local ep = LocalPlayer():EyePos()
	local fw = LocalPlayer():EyeAngles():Forward() * 512

	local exPos = nw:Get("Positions") or {}
	if not istable(exPos) then return end

	local hit = closestIntersection(exPos, ep, fw)

	for k,v in pairs(exPos) do
		local isHov = v == hit

		if isHov then
			an:MemberLerp(bufFrac, v, 1, 0.2, 0, 0.3)
		else
			an:MemberLerp(bufFrac, v, 0, 0.3, 0, 0.3)
		end

		draw.LerpColor(bufFrac[v] or 0, curCol, lazy.GetSet("OreMarkRed", Color, 200, 60, 60, 120), lazy.GetSet("OreMarkGr", Color, 60, 200, 60, 120))

		visv1 = v1 * ((bufFrac[v] or 0) / 8 + 1)
		visv2 = v2 * ((bufFrac[v] or 0) / 8 + 1)

		render.SetColorMaterialIgnoreZ()
		render.DrawBox(v, angle_zero, visv2, visv1, curCol)
	end

	local lPos = nw:Get(LocalPlayer()) or {}

	if not hit then
		hit = closestIntersection(lPos, ep, fw)
	else
		hit = false
	end


	for k,v in pairs(lPos) do
		local isHov = v == hit

		if isHov then
			an:MemberLerp(bufFrac, v, 1, 0.2, 0, 0.3)
		else
			an:MemberLerp(bufFrac, v, 0, 0.3, 0, 0.3)
		end

		draw.LerpColor(bufFrac[v] or 0, curCol, Colors.Red, Colors.Golden)

		visv1 = v1 * ((bufFrac[v] or 0) / 4 + 1)
		visv2 = v2 * ((bufFrac[v] or 0) / 4 + 1)

		render.SetColorMaterialIgnoreZ()
		render.DrawBox(v, angle_zero, visv2, visv1, curCol)
	end
end)