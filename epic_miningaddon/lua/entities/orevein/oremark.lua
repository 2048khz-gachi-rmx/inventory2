do return end

StartTool("OreMark")

_OreData = _OreData or {}

file.CreateDir("inventory/")
local function readOreData(force)
	if _OreData and not force then return _OreData end

	local dat = file.Read("inventory/ore_positions.dat", "DATA")

	if not dat then
		file.Write("inventory/ore_positions.dat", "")
		return
	end

	_OreData = util.JSONToTable(dat)
	return _OreData
end

readOreData(true)

local function writeOreData()
	file.Write("inventory/ore_positions.dat", util.TableToJSON(_OreData))
end

local nw = Networkable("Orepositions")
local bufs = nw.Buffers or muldim:new()
nw.Buffers = bufs

nw.AlreadyNetworkedPlyBuf = {}
nw.AlreadyNetworkedPos = {}

nw.Filter = function(self, ply)
	return ply:IsSuperAdmin()
end

nw:On("WriteChangeValue", 1, function(self, k, v, plyList)
	if not IsPlayer(k) and k ~= "Positions" then return end
	local isPos = k == "Positions"

	local alw = isPos and self.AlreadyNetworkedPos or self.AlreadyNetworkedPlyBuf

	self.AwarePlayers = self.AwarePlayers or {}

	local ignoreKnowledge = false

	for k,v in ipairs(plyList) do
		if not self.AwarePlayers[k] then ignoreKnowledge = true end
		self.AwarePlayers[k] = true
	end

	local toNW = {}
	local amt = 0

	for k, pos in pairs(v) do
		if alw[k] == pos and not ignoreKnowledge then continue end
		toNW[k] = pos
		amt = amt + 1
		alw[k] = pos
	end

	for k, _ in pairs(alw) do
		if not v[k] then
			toNW[k] = false
			alw[k] = nil
			amt = amt + 1
		end
	end

	net.WriteUInt(amt, isPos and 16 or 8)
	for k,v in pairs(toNW) do
		net.WriteUInt(k, isPos and 16 or 8)
		net.WriteBool(v and true or false)
		if v then net.WriteVector(v) end
	end

	return false
end)

nw:On("ReadChangeValue", 1, function(self, k)
	if not IsPlayer(k) and k ~= "Positions" then return end
	local isPos = k == "Positions"

	local amt = net.ReadUInt(isPos and 16 or 8)

	self:Set(k, self:Get(k) or {})

	local poses = self:Get(k)

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

if SERVER then
	local poses = readOreData()
	nw:Set("Positions", poses)
	nw:Network()
end

local v1 = Vector(4, 4, 4)
local v2 = -v1

local visv1
local visv2

local function closestIntersection(t, ep, fw)
	local hit, hitDist, key = nil, math.huge

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
	if CLIENT then return true end

	local where = tr.HitPos
	local ply = self:GetOwner()
	bufs:Insert(where, ply)

	if SERVER then
		nw:Set(ply, bufs[ply])
		nw:Network()
	end

	return true
end

function TOOL:Allowed()
	return self:GetOwner():IsSuperAdmin()
end

function TOOL:RightClick(tr)
	if CLIENT then return true end
	local ply = self:GetOwner()

	if ply:KeyDown(IN_WALK) and not ply:KeyDown(IN_SPEED) then

		if CurTime() - (ply.LastOreClear or 0) > 0.7 then
			ply.OresCleaned = 0
			return
		end

		ply.LastOreClear = CurTime()
		ply.OresCleaned = (ply.OresCleaned or 0) + 1

		if ply.OresCleaned == 2 then
			bufs[ply] = {}
			nw:Set(ply, bufs[ply])
			nw:Network()

			ply.OresCleaned = 0
		end
		return
	end

	ply.LastOreClear = CurTime()
	ply.OresCleaned = 0

	local ep = ply:EyePos()
	local fw = ply:EyeAngles():Forward() * 512

	local hit, key = closestIntersection(bufs:GetOrSet(ply), ep, fw)

	if hit then
		bufs[ply][key] = nil
		nw:Set(ply, bufs[ply])
		nw:Network()
	else
		local hit, key = closestIntersection(_OreData, ep, fw)
		local sure = ply:KeyDown(IN_WALK) and ply:KeyDown(IN_SPEED)
		if hit then
			if not sure then ply:ChatAddText(color_white, "Hold SHIFT + ALT if you want to", Colors.Red, " remove existing positions", color_white, ".") return end
			table.remove(_OreData, key)
			ply:ChatAddText(Colors.Red, "Removed existing position.")

			nw:Set("Positions", _OreData)
			nw:Network()

			timer.Create("OreSave", 2, 1, writeOreData)
		end
	end

	return true
end

function TOOL:Reload()
	if CLIENT then return end


	local ow = self:GetOwner()

	local newPoses = bufs[ow]
	if not newPoses then return end

	local amt = 0

	for k,v in pairs(newPoses) do
		amt = amt + 1
		_OreData[#_OreData + 1] = v
	end

	writeOreData()

	printf("Player %s(%s) saved %d new ore positions.", ow:Nick(), ow:SteamID64(), amt)

	bufs[ow] = {}
	nw:Set(ow, bufs[ow])

	nw:Set("Positions", _OreData)
	nw:Network()
end

EndTool()


local curCol = Colors.Golden:Copy()
local bufFrac = WeakTable(nil, "k")
local an = Animatable("Vectahs")

hook.Add("PostDrawTranslucentRenderables", "OresRender", function(a, b)
	if a or b then return end

	local ep = LocalPlayer():EyePos()
	local fw = LocalPlayer():EyeAngles():Forward() * 512

	local exPos = nw:Get("Positions") or {}
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