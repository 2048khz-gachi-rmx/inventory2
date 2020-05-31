
local function inc(str)
	if CLIENT then 
		include(str)
	end
	AddCSLuaFile(str)
	
end
local function doit()
	inc('inventory/client/cl_invfuncs.lua')
	inc('inventory/client/cl_invvalues.lua')
	inc('inventory/client/cl_invpanels.lua')
	inc('inventory/client/cl_invcontext.lua')

	hdl.DownloadFile("https://vaati.net/Gachi/shared/blank.mp3", "blank.dat", function() end)

	hook.Remove("OnInventoryLoad", "_InvLoadCL")
end

if not Inventory or not Items then 
	hook.Add("OnInventoryLoad", "_InvLoadCL", doit)
else 
	doit()
end
