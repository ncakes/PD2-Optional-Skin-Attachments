if RequiredScript ~= "core/lib/system/coresystem" then
	log("[ncUtils] ERROR: invalid initialization hook, skipping: " .. ModPath)
	return
end

if _G.ncUtils and ncUtils.devmode then
	return
end

local version = 5

if _G.ncUtils and ncUtils.version and ncUtils.version >= version then
	return
end

_G.ncUtils = {
	version = version,
	path = ModPath .. "ncUtils/",
}

dofile(ncUtils.path .. "string.lua")
dofile(ncUtils.path .. "calc.lua")
dofile(ncUtils.path .. "file_io.lua")
dofile(ncUtils.path .. "settings.lua")
dofile(ncUtils.path .. "menu.lua")
dofile(ncUtils.path .. "localization.lua")
dofile(ncUtils.path .. "bootstrap.lua")
dofile(ncUtils.path .. "compatibility.lua")
