local Base = Inventory.BaseItemObjects.Generic
Base._ItemModelPool = Base._ItemModelPool or muldim:new()

local IMP = Base._ItemModelPool
local time = 20

function Base.CleanupIMP()
	for itm, dat in pairs(IMP) do
		dat[1]:Remove()
	end

	table.Empty(Base._ItemModelPool)
end

timer.Create("Inv_CSEntCleanup", 5, 0, function()
	if table.IsEmpty(IMP) then return end

	local st = SysTime()
	local toNil = {}

	for itm, dat in pairs(IMP) do
		if st - dat[2] > time then
			dat[1]:Remove()
			IMP[itm] = nil
		end
	end

	for k,v in ipairs(toNil) do
		IMP[v] = nil -- lua moment
	end
end)

local function getModel(itm, mdl)
	if IMP:Get(itm) then
		local dat = IMP:Get(itm)
		if dat[1]:IsValid() then
			dat[2] = SysTime()
			return dat[1], dat
		end
	end

	local ent = ClientsideModel(itm:GetModel())
	local entry = {ent, SysTime()}
	IMP:Set(entry, itm)
	ent:SetModel(mdl)

	if itm:GetModelColor() then
		ent:SetColor(itm:GetModelColor())
		print("setmodelcolor", itm:GetModelColor(), ent)
	end

	ent:SetNoDraw(true)
	itm:GetBase():Emit("UpdateModel", itm, ent)

	return ent, entry
end

function Base:Paint3D_Model(pos, ang, itm)
	local mdl, dat = getModel(itm, itm:GetModel())

	if not dat[3] then
		local mins, maxs = mdl:GetModelBounds()
		mins:Add(maxs)
		mins:Mul(vector_up)
		mins:Div(2)

		dat[3] = mins
	end

	pos = pos - dat[3]

	render.OverrideDepthEnable(true, false)
		mdl:SetPos(pos)
		mdl:SetAngles(ang)

		mdl:SetNoDraw(false)

			if itm:GetModelColor() then
				mdl:SetColor(itm:GetModelColor())
				print(itm:GetModelColor(), mdl:GetModel())
			end

			itm:GetBase():Emit("PrePaintModel", itm, mdl)
			mdl:DrawModel()
			itm:GetBase():Emit("PostPaintModel", itm, mdl)

		mdl:SetNoDraw(true)
	render.OverrideDepthEnable(false, false)
end

local tVec = Vector()

function Base:Paint3D_NoModel(pos, ang, itm)
	local fAng = (pos - EyePos()):Angle()
	fAng:RotateAroundAxis(fAng:Right(), 90)
	fAng:RotateAroundAxis(fAng:Up(), -90)

	local scale = 0.075
	local sz = 256

	tVec:Set(pos)
	local off = fAng:Right()
	off:Add(fAng:Forward())
	off:Mul(sz / 2 * scale)

	tVec:Sub(off)

	cam.Start3D2D(tVec, fAng, scale)
		self:Emit("PaintSprite", itm, sz)
	cam.End3D2D()
end

function Base:Paint3D(pos, ang, itm)
	local mdl = self:GetModel()
	if mdl then
		self:Paint3D_Model(pos, ang, itm)
	else
		self:Paint3D_NoModel(pos, ang, itm)
	end

	--[[render.SetColorMaterial()
	render.DrawBox(pos, ang, Vector(-16, -16, -16), Vector(16, 16, 16), color_white)]]
end