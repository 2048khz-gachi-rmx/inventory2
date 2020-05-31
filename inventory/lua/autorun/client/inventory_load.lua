
local function inc(str)

	include(str)
	AddCSLuaFile(str)

end
--[[
inc('inventory/client/cl_invfuncs.lua')
inc('inventory/client/cl_invvalues.lua')
inc('inventory/client/cl_invpanels.lua')
inc('inventory/client/cl_invcontext.lua')
]]