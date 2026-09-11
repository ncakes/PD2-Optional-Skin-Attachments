if _G.ncUtils and _G.ncUtils.devmode then
	return
end

local version = 2

if _G.ncUtils and _G.ncUtils.version and _G.ncUtils.version >= version then
	return
end

_G.ncUtils = {
	version = version,
}

dofile(ModPath .. "lua/ncUtils/file_io.lua")
dofile(ModPath .. "lua/ncUtils/string.lua")
dofile(ModPath .. "lua/ncUtils/menu.lua")
dofile(ModPath .. "lua/ncUtils/settings.lua")
dofile(ModPath .. "lua/ncUtils/localization.lua")
dofile(ModPath .. "lua/ncUtils/compatibility.lua")
