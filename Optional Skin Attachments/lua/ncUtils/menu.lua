ncUtils.Menu = {}

function ncUtils.Menu:register_default_callbacks(Mod)
	local menu_callback_prefix = Mod and Mod.meta and Mod.meta.menu_callback_prefix
	if not menu_callback_prefix then
		return
	end

	MenuCallbackHandler[menu_callback_prefix .. "_callback_toggle"] = function(self, item)
		Mod.settings[item:name()] = item:value() == "on"
	end

	MenuCallbackHandler[menu_callback_prefix .. "_callback_multi"] = function(self, item)
		Mod.settings[item:name()] = item:value()
	end

	MenuCallbackHandler[menu_callback_prefix .. "_callback_slider"] = function(self, item)
		local decimals = item._decimal_count or 2
		local multiplier = 10 ^ decimals
		local value = math.floor(item:value() * multiplier + 0.5) / multiplier

		Mod.settings[item:name()] = value
	end

	MenuCallbackHandler[menu_callback_prefix .. "_callback_button"] = function(self, item)
		local name = item:name() .. "_callback"
		local callback = Mod[name]
		if type(callback) ~= "function" then
			log("ncUtils: button callback not found: " .. tostring(Mod.meta.mod_path) .. " -> " .. tostring(name))
			return
		end

		callback(Mod)
	end

	MenuCallbackHandler[menu_callback_prefix .. "_callback_back"] = function(self)
		ncUtils.Settings:save(Mod)
	end
end

function ncUtils.Menu:get(Mod)
	local menu_id = Mod and Mod.meta and Mod.meta.menu_id
	local menu = menu_id and MenuHelper:GetMenu(menu_id)
	return menu
end

function ncUtils.Menu:get_item(setting_id, Mod)
	local menu = self:get(Mod)
	if not menu then
		return
	end

	local menu_items = menu:items()
	for _, item in ipairs(menu_items) do
		local name = item:name()
		if name == setting_id then
			return item
		end
	end
end

--Visually set a menu item value, does not modify settings
function ncUtils.Menu:set_item_value(setting_id, value, Mod)
	local item = self:get_item(setting_id, Mod)
	if not item then
		return
	end

	if item:type() == "toggle" and type(value) == "boolean" then
		item:set_value(value and "on" or "off")
	elseif item:type() == "slider" and type(value) == "number" then
		item:set_value(value)
	elseif item:type() == "multi_choice" and type(value) == "number" then
		item:set_value(value)
	end
end

--Revert a menu item value to whatever is in Mod.settings
function ncUtils.Menu:revert_item_value(setting_id, Mod)
	local item = self:get_item(setting_id, Mod)
	if not item then
		return
	end

	local value = Mod.settings[setting_id]
	self:set_item_value(setting_id, value, Mod)
end

function ncUtils.Menu:disable_item(setting_id, Mod)
	local item = self:get_item(setting_id, Mod)
	if not item then
		return
	end

	item:set_enabled(false)
end

function ncUtils.Menu:enable_item(setting_id, Mod)
	local item = self:get_item(setting_id, Mod)
	if not item then
		return
	end

	item:set_enabled(true)
end

--Get the name (text_id) of the current multiple choice setting
function ncUtils.Menu:get_multi_choice_name(setting_id, Mod)
	local item = self:get_item(setting_id, Mod)
	if not item then
		return
	end

	if item:type() ~= "multi_choice" then
		return
	end

	local value = Mod.settings[setting_id]
	local options = item:options()
	local option = value and options and options[value]
	local option_name = option and option._parameters and option._parameters.text_id

	return option_name
end

--Multiple choice items must follow the name pattern <setting_id>_<suffix>
--Returns nil if the item does not match the name pattern
--Note: "" is not a valid suffix (will return nil)
function ncUtils.Menu:get_multi_choice_suffix(setting_id, Mod)
	local choice = self:get_multi_choice_name(setting_id, Mod)
	local prefix = setting_id .. "_"
	if not choice or not ncUtils.String:head_match(choice, prefix) then
		return
	end

	local suffix = choice:sub(#prefix + 1)
	return suffix ~= "" and suffix or nil
end
