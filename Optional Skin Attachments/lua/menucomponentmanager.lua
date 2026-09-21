_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

if _G.BeardLib then
	return
end

--Use the upper/lower receiver icon for upper/lower body
local orig_MenuComponentManager_get_texture_from_mod_type = MenuComponentManager.get_texture_from_mod_type
function MenuComponentManager:get_texture_from_mod_type(type, ...)
	if type == "upper_body" then
		return orig_MenuComponentManager_get_texture_from_mod_type(self, "upper_reciever", ...)
	end
	if type == "lower_body" then
		return orig_MenuComponentManager_get_texture_from_mod_type(self, "lower_reciever", ...)
	end
	return orig_MenuComponentManager_get_texture_from_mod_type(self, type, ...)
end
