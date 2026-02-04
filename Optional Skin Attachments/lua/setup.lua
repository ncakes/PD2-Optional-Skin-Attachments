if _G.OSA then return end

_G.OSA = {}
OSA.meta = {
	mod_path = ModPath,
	save_path = SavePath,
	menu_id = "osa_options_menu",
	menu_file = ModPath.."menu/options.json",
	save_file = SavePath.."osa_settings.json",
}

function OSA:save_json(path, data)
	local file = io.open(path, "w+")
	file:write(json.encode(data))
	file:close()
end

function OSA:load_json(path)
	local file = io.open(path, "r")
	local data = json.decode(file:read("*all")) or {}
	file:close()
	return data
end

function OSA:save_settings()
	self:save_json(self.meta.save_file, self.settings)
end

function OSA:load_settings()
	local file = io.open(self.meta.save_file, "r")
	if file then
		local data = json.decode(file:read("*all")) or {}
		file:close()
		for k, _ in pairs(self.settings) do
			if data[k] ~= nil then
				self.settings[k] = data[k]
			end
		end
	end
end

OSA.settings = {
	osa_gen1_support = true,
	osa_autobuy = false,
	osa_swap_buckshot = true,
	osa_show_failure = true,
	osa_remove_beardlib_blueprints = true,

	osa_preview_mode = 1,

	osa_paint_scheme = 1,
	osa_color_wear = 1,
	osa_pattern_scale = 1,

	osa_hide_unowned = false,
	osa_swap_legend = 1,
}
OSA:load_settings()
OSA.data = OSA:load_json(OSA.meta.mod_path.."data/gen1_legend.json")

Hooks:Add("LocalizationManagerPostInit", "OSA-Hooks-LocalizationManagerPostInit", function(loc)
	loc:load_localization_file(OSA.meta.mod_path.."localizations/english.json")
end)

Hooks:Add("MenuManagerInitialize", "OSA-Hooks-MenuManagerInitialize", function(menu_manager)
	local Mod = OSA

	MenuCallbackHandler.osa_callback_toggle = function(self, item)
		Mod.settings[item:name()] = item:value() == "on"
		Mod:update_menu_options()
	end

	MenuCallbackHandler.osa_callback_multi = function(self, item)
		Mod.settings[item:name()] = item:value()
		Mod:update_menu_options()
	end

	MenuCallbackHandler.osa_callback_save = function(self, item)
		Mod:save_settings()
		managers.blackmarket:osa_set_visible_parts()
	end

	MenuHelper:LoadFromJsonFile(Mod.meta.menu_file, Mod, Mod.settings)
end)

--Disable legendary attachments option if gen1 support is not enabled
--Visual change only
function OSA:update_menu_options()
	local item = self:get_menu_item("osa_hide_unowned")
	if not self.settings.osa_gen1_support then
		item.selected = 1
		item._enabled = false
		item:dirty_callback()
	else
		item.selected = self.settings.osa_hide_unowned and 1 or 2
		item._enabled = true
		item:dirty_callback()
	end
end

function OSA:get_menu_item(setting_id)
	local menu = MenuHelper:GetMenu(self.meta.menu_id)
	for _, item in pairs(menu._items) do
		local name = item._parameters and item._parameters.name
		if name == setting_id then
			return item
		end
	end
end

--Multiple choice options must be named as "<setting_id>_name" for this to work
function OSA:get_choice_name(setting_id)
	local value = self.settings[setting_id]
	if not value then
		return
	end

	local item = self:get_menu_item(setting_id)
	local options = item._options or item._all_options
	local text_id = options[value]._parameters.text_id
	return string.sub(text_id, string.len(setting_id)+2)
end

function OSA:set_weapon_color_defaults(data)
	if self.settings.osa_color_wear > 1 then
		data.cosmetic_quality = self:get_choice_name("osa_color_wear")
	end
	if self.settings.osa_paint_scheme > 1 then
		data.cosmetic_color_index = self.settings.osa_paint_scheme - 1
	end
	--Default weapon color has no pattern scale so this does nothing at the moment
	--Need to change MenuCustomizeWeaponColorInitiator:setup_node to set a default pattern scale when going from a color without patterns to one with patterns
	--Do not change default pattern_scale in tweak_data, that affects other things like weapon skins (e.g. CAR-4 Stripe On, 5/7 AP Possessed)
	if self.settings.osa_pattern_scale > 1 then
		data.cosmetic_pattern_scale = self.settings.osa_pattern_scale - 1
	end
end

--Couldn't keep attachments
function OSA:failure_dialog(part_list)
	local menu_title = managers.localization:text("osa_dialog_title")
	local menu_message = managers.localization:text("osa_dialog_could_not_keep")
	local parts_tweak_data = tweak_data.weapon.factory.parts
	for _, part_id in ipairs(part_list) do
		if parts_tweak_data[part_id] and parts_tweak_data[part_id].name_id then
			menu_message = menu_message .. "\n - " .. managers.localization:text(parts_tweak_data[part_id].name_id)
		else
			menu_message = menu_message .. "\n - " .. part_id
		end
	end
	local menu_options = {{
		text = managers.localization:text("dialog_ok"),
		is_cancel_button = true,
	}}
	QuickMenu:new(menu_title, menu_message, menu_options):Show()
end

--Choose attachments dialog
function OSA:weapon_cosmetics_handler(params)
	local menu_title = managers.localization:text("osa_dialog_title")

	local menu_message
	if not params.preview then
		if params.add then
			menu_message = managers.localization:text("dialog_weapon_cosmetics_add", {cosmetic = params.name})
		else
			menu_message = managers.localization:text("dialog_weapon_cosmetics_remove", {cosmetic = params.name})
		end

		if params.locked then
			menu_message = menu_message.."\n\n"..managers.localization:text("dialog_weapon_cosmetics_locked")
		else
			menu_message = menu_message.."\n\n"..managers.localization:text("osa_dialog_choose_attachments")
		end
	else
		menu_message = managers.localization:text("osa_dialog_choose_attachments_preview")
	end

	local menu_options = {}
	if not params.locked then
		table.insert(menu_options, {
			text = managers.localization:text("osa_dialog_keep"),
			callback = function()
				self._mode = "keep"
				params.yes_clbk()
			end,
			is_focused_button = (#menu_options == 0),
		})
	end
	if params.can_use_blueprint then
		table.insert(menu_options, {
			text = managers.localization:text("osa_dialog_replace"),
			callback = function()
				self._mode = "replace"
				params.yes_clbk()
			end,
			is_focused_button = (#menu_options == 0),
		})
	end
	if not params.locked then
		table.insert(menu_options, {
			text = managers.localization:text("osa_dialog_remove"),
			callback = function()
				self._mode = "remove"
				params.yes_clbk()
			end,
		})
	end
	table.insert(menu_options, {
		text = managers.localization:text("dialog_cancel"),
		is_cancel_button = true,
	})
	QuickMenu:new(menu_title, menu_message, menu_options):Show()
end

function OSA:preview_wear_handler(params)
	if not params.choose_wear then
		self:preview_mods_handler(params)
		return
	end

	local menu_title = managers.localization:text("osa_dialog_title")
	local menu_message = managers.localization:text("osa_dialog_choose_quality")

	local menu_options = {}
	for _, quality in ipairs({"mint", "fine", "good", "fair", "poor"}) do
		table.insert(menu_options, {
			text = managers.localization:text("bm_menu_quality_"..quality),
			callback = function()
				params.data.cosmetic_quality = quality
				self:preview_mods_handler(params)
			end,
			is_focused_button = (#menu_options == 0),
		})
	end
	table.insert(menu_options, {
		text = managers.localization:text("dialog_cancel"),
		is_cancel_button = true,
	})
	QuickMenu:new(menu_title, menu_message, menu_options):Show()
end

function OSA:preview_mods_handler(params)
	local yes_clbk = function()
		params.data._osa_done = true
		local bmg = managers.menu_component._blackmarket_gui
		bmg:preview_cosmetic_on_weapon_callback(params.data)
	end

	if not params.choose_mods then
		self._mode = "keep"
		yes_clbk()
		return
	end

	params.yes_clbk = yes_clbk
	params.preview = true
	self:weapon_cosmetics_handler(params)
end
