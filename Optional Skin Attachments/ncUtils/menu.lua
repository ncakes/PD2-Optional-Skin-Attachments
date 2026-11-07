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
		--Use internal field to ensure runtime changes are reflected.
		local decimals = item._decimal_count or 2
		Mod.settings[item:name()] = ncUtils.Calc:round(item:value(), decimals)
	end

	MenuCallbackHandler[menu_callback_prefix .. "_callback_input"] = function(self, item)
		Mod.settings[item:name()] = item:value()
	end

	MenuCallbackHandler[menu_callback_prefix .. "_callback_button"] = function(self, item)
		local name = item:name() .. "_callback"
		local callback = Mod[name]
		if type(callback) ~= "function" then
			log(string.format("[ncUtils] MenuCallbackHandler.%s missing or invalid button callback: %s", menu_callback_prefix .. "_callback_button", name))
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
	if not menu_id then
		return
	end

	return self:_get_menu(menu_id)
end

function ncUtils.Menu:_get_menu(menu_id)
	return MenuHelper:GetMenu(menu_id)
end

function ncUtils.Menu:get_item(setting_id, Mod)
	local menu_id = Mod and Mod.meta and Mod.meta.menu_id
	if not menu_id then
		return
	end

	return self:_get_item_by_menu_id(setting_id, menu_id, {})
end

function ncUtils.Menu:_get_item_by_menu_id(setting_id, menu_id, visited)
	local menu = self:_get_menu(menu_id)
	if not visited then
		return menu and menu:item(setting_id)
	end

	visited[menu_id] = true

	if menu then
		for _, item in ipairs(menu:items()) do
			if item:name() == setting_id then
				return item
			end
			local next_node = item:parameter("next_node")
			if next_node and not visited[next_node] then
				local found = self:_get_item_by_menu_id(setting_id, next_node, visited)
				if found then
					return found
				end
			end
		end
	end
end

--Visually set a menu item value, does not modify settings
function ncUtils.Menu:set_item_value(setting_id, value, Mod)
	local menu_id = Mod and Mod.meta and Mod.meta.menu_id
	if not menu_id then
		return
	end

	self:_set_item_value_by_menu_id(setting_id, value, menu_id, {})
end

--Revert a menu item value to whatever is in Mod.settings
function ncUtils.Menu:revert_item_value(setting_id, Mod)
	local menu_id = Mod and Mod.meta and Mod.meta.menu_id
	if not menu_id then
		return
	end

	local value = Mod.settings[setting_id]
	self:_set_item_value_by_menu_id(setting_id, value, menu_id, {})
end

function ncUtils.Menu:_set_item_value_by_menu_id(setting_id, value, menu_id, visited)
	local item = self:_get_item_by_menu_id(setting_id, menu_id, visited)
	if not item then
		return
	end

	self:_set_item_value(item, value)
end

function ncUtils.Menu:_set_item_value(item, value)
	local item_type = item:type()

	if item_type == "toggle" then
		if type(value) == "boolean" then
			item:set_value(value and "on" or "off")
		end
	elseif item_type == "slider" then
		if type(value) == "number" then
			item:set_value(value)
		end
	elseif item_type == "multi_choice" then
		if type(value) == "number" or type(value) == "string" then
			item:set_value(value)
		end
	elseif item_type == "input" then
		if type(value) == "string" then
			item:set_value(value)
			--GUI doesn't refresh automatically, call it manually.
			item:dirty()
		end
	end
end

function ncUtils.Menu:set_item_enabled(setting_id, enabled, Mod)
	local menu_id = Mod and Mod.meta and Mod.meta.menu_id
	if not menu_id then
		return
	end

	self:_set_item_enabled_by_menu_id(setting_id, enabled, menu_id, {})
end

function ncUtils.Menu:disable_item(setting_id, Mod)
	self:set_item_enabled(setting_id, false, Mod)
end

function ncUtils.Menu:enable_item(setting_id, Mod)
	self:set_item_enabled(setting_id, true, Mod)
end

function ncUtils.Menu:_set_item_enabled_by_menu_id(setting_id, enabled, menu_id, visited)
	local item = self:_get_item_by_menu_id(setting_id, menu_id, visited)
	if not item then
		return
	end

	item:set_enabled(enabled)
end

--Get the text_id of the multiple choice option selected in Mod.settings
function ncUtils.Menu:get_multi_choice_name(setting_id, Mod)
	local menu_id = Mod and Mod.meta and Mod.meta.menu_id
	if not menu_id then
		return
	end

	local value = Mod.settings[setting_id]
	return self:_get_multi_choice_name_by_menu_id(setting_id, value, menu_id, {})
end

function ncUtils.Menu:_get_multi_choice_name_by_menu_id(setting_id, value, menu_id, visited)
	local item = self:_get_item_by_menu_id(setting_id, menu_id, visited)
	if not item then
		return
	end

	return self:_get_multi_choice_name(item, value)
end

function ncUtils.Menu:_get_multi_choice_name(item, value)
	if item:type() ~= "multi_choice" then
		return
	end

	for _, option in ipairs(item:options()) do
		local parameters = option:parameters()
		if parameters.value == value then
			return parameters.text_id
		end
	end
end

--Multiple choice items must follow the name pattern <setting_id>_<suffix>
--Returns nil if the item does not match the name pattern
--Note: "" is not a valid suffix (will return nil)
function ncUtils.Menu:get_multi_choice_suffix(setting_id, Mod)
	local menu_id = Mod and Mod.meta and Mod.meta.menu_id
	if not menu_id then
		return
	end

	local value = Mod.settings[setting_id]
	return self:_get_multi_choice_suffix_by_menu_id(setting_id, value, menu_id, {})
end

function ncUtils.Menu:_get_multi_choice_suffix_by_menu_id(setting_id, value, menu_id, visited)
	local choice = self:_get_multi_choice_name_by_menu_id(setting_id, value, menu_id, visited)
	local prefix = setting_id .. "_"
	if not choice or not ncUtils.String:head_match(choice, prefix) then
		return
	end

	local suffix = choice:sub(#prefix + 1)
	return suffix ~= "" and suffix or nil
end
