--Compatibility wrappers for v1
function ncUtils:save_json(path, data)
	log("ncUtils:save_json is deprecated, use ncUtils.FileIO:save_json")
	return ncUtils.FileIO:save_json(path, data, true)
end

function ncUtils:load_json(path)
	log("ncUtils:load_json is deprecated, use ncUtils.FileIO:load_json")
	return ncUtils.FileIO:load_json(path)
end

function ncUtils:save_settings(Mod)
	log("ncUtils:save_settings is deprecated, use ncUtils.Settings:save")
	return ncUtils.Settings:save(Mod)
end

function ncUtils:load_settings(Mod)
	log("ncUtils:load_settings is deprecated, use ncUtils.Settings:load")
	return ncUtils.Settings:load(Mod)
end

function ncUtils:get_menu(Mod)
	log("ncUtils:get_menu is deprecated, use ncUtils.Menu:get")
	return ncUtils.Menu:get(Mod)
end

function ncUtils:get_menu_item(setting_id, Mod)
	log("ncUtils:get_menu_item is deprecated, use ncUtils.Menu:get_item")
	return ncUtils.Menu:get_item(setting_id, Mod)
end

function ncUtils:set_menu_item_value(setting_id, value, Mod)
	log("ncUtils:set_menu_item_value is deprecated, use ncUtils.Menu:set_item_value")
	return ncUtils.Menu:set_item_value(setting_id, value, Mod)
end

function ncUtils:revert_menu_item_value(setting_id, Mod)
	log("ncUtils:revert_menu_item_value is deprecated, use ncUtils.Menu:revert_item_value")
	return ncUtils.Menu:revert_item_value(setting_id, Mod)
end

function ncUtils:disable_menu_item(setting_id, Mod)
	log("ncUtils:disable_menu_item is deprecated, use ncUtils.Menu:disable_item")
	return ncUtils.Menu:disable_item(setting_id, Mod)
end

function ncUtils:enable_menu_item(setting_id, Mod)
	log("ncUtils:enable_menu_item is deprecated, use ncUtils.Menu:enable_item")
	return ncUtils.Menu:enable_item(setting_id, Mod)
end

function ncUtils:get_multi_choice_name(setting_id, Mod)
	log("ncUtils:get_multi_choice_name is deprecated, use ncUtils.Menu:get_multi_choice_name")
	return ncUtils.Menu:get_multi_choice_name(setting_id, Mod)
end
