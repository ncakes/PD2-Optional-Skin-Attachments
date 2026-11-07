--Compatibility wrappers for v1
function ncUtils:save_json(path, data)
	return ncUtils.FileIO:save_json(path, data, true)
end

function ncUtils:load_json(path)
	return ncUtils.FileIO:load_json(path)
end

function ncUtils:save_settings(Mod)
	return ncUtils.Settings:save(Mod)
end

function ncUtils:load_settings(Mod)
	return ncUtils.Settings:load(Mod)
end

function ncUtils:get_menu(Mod)
	return ncUtils.Menu:get(Mod)
end

function ncUtils:get_menu_item(setting_id, Mod)
	return ncUtils.Menu:get_item(setting_id, Mod)
end

function ncUtils:set_menu_item_value(setting_id, value, Mod)
	return ncUtils.Menu:set_item_value(setting_id, value, Mod)
end

function ncUtils:revert_menu_item_value(setting_id, Mod)
	return ncUtils.Menu:revert_item_value(setting_id, Mod)
end

function ncUtils:disable_menu_item(setting_id, Mod)
	return ncUtils.Menu:disable_item(setting_id, Mod)
end

function ncUtils:enable_menu_item(setting_id, Mod)
	return ncUtils.Menu:enable_item(setting_id, Mod)
end

function ncUtils:get_multi_choice_name(setting_id, Mod)
	return ncUtils.Menu:get_multi_choice_name(setting_id, Mod)
end
