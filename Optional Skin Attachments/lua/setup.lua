if _G.OSA then return end
dofile(ModPath.."lua/ncUtils/init.lua")

_G.OSA = {}
OSA.meta = {
	mod_path = ModPath,
	loc_path = ModPath.."loc/",
	language = "en",
	menu_id = "osa_options_menu",
	menu_callback_prefix = "osa",
	menu_file = ModPath.."menu/options.json",
	save_file = SavePath.."osa_settings.json",
}

OSA.settings = {
	gen1_legend_support = true,
	hide_unowned_legend = false,
	autoswap_legend = false,

	always_keep = false,
	autobuy_missing = false,
	show_failure = true,
	remove_beardlib_blueprints = true,

	osa_preview_mode = 1,
	auto_clear_preview = true,

	osa_paint_scheme = 1,
	osa_color_wear = 1,
	osa_pattern_scale = 1,
}
OSA.save_migration = {
	{
		file = SavePath.."osa_settings.json",
		key_map = {
			osa_gen1_support = "gen1_legend_support",
			osa_hide_unowned = "hide_unowned_legend",
			osa_autobuy = "autobuy_missing",
			osa_show_failure = "show_failure",
			osa_remove_beardlib_blueprints = "remove_beardlib_blueprints",
		}
	}
}
ncUtils.Settings:load(OSA)

--Recommended settings when using SDSS
OSA.sdss_preset = {
	gen1_legend_support = true,--This is already force-enabled when SDSS is installed.
	hide_unowned_legend = false,
	autoswap_legend = true,--Will do nothing if AOLA is not installed so don't worry.

	always_keep = true,
	autobuy_missing = true,
	show_failure = true,
	remove_beardlib_blueprints = true,
}

OSA.legend_data = ncUtils.FileIO:load_json(OSA.meta.mod_path.."data/legend_data.json")

Hooks:Add("LocalizationManagerPostInit", "OSA-Hooks-LocalizationManagerPostInit", function(loc)
	ncUtils.Localization:load(loc, OSA)

	--Generate localizations for part names and "skin required" description
	local ptd = tweak_data and tweak_data.weapon and tweak_data.weapon.factory and tweak_data.weapon.factory.parts
	for skin_id, skin_data in pairs(OSA.legend_data) do
		--Hardcode skin name, game doesn't localize it anyways
		local skin_name = skin_data.name

		--"Skin required" description
		do
			local k = "bm_req_legend_equipped_" .. skin_id
			local v = loc:text("bm_req_legend_equipped_template", {skin = skin_name})
			loc:add_localized_strings({[k] = v})
		end

		--Part names
		for part_id, fallback_part_type in pairs(skin_data.parts) do
			local k = ptd and ptd[part_id] and ptd[part_id].name_id
			if k then
				local part_type = ptd[part_id].legend_part_name_type or fallback_part_type
				local v = loc:text("bm_legend_part_name_template_"..part_type, {skin = skin_name})
				loc:add_localized_strings({[k] = v})
			end
		end
	end
end)

Hooks:Add("MenuManagerInitialize", "OSA-Hooks-MenuManagerInitialize", function(menu_manager)
	ncUtils.Menu:register_default_callbacks(OSA)

	--Set visible parts and update BeardLib blueprints immediately
	MenuCallbackHandler.osa_callback_back = function(self)
		ncUtils.Settings:save(OSA)
		managers.blackmarket:osa_set_visible_parts()
		if OSA.settings.remove_beardlib_blueprints then
			OSA:remove_custom_weapon_blueprints()
		else
			OSA:restore_custom_weapon_blueprints()
		end
	end

	--If new user (no save) and using SDSS, use sdss_preset.
	if _G.SDSS and not ncUtils.Settings:exists(OSA) then
		for k, v in pairs(OSA.sdss_preset) do
			OSA.settings[k] = v
		end
		ncUtils.Settings:save(OSA)
	end

	MenuHelper:LoadFromJsonFile(OSA.meta.menu_file, OSA, OSA.settings)
end)

--Add SDSS preset button to menu
Hooks:Add("MenuManagerBuildCustomMenus", "OSA-Hooks-MenuManagerBuildCustomMenus", function(menu_manager, nodes)
	if not _G.SDSS then
		return
	end

	MenuHelper:AddDivider({
		id = "sdss_preset_divider",
		size = 16,
		menu_id = "osa_options_menu",
		priority = -1,
	})

	MenuHelper:AddButton({
		id = "apply_sdss_preset",
		title = "osa_apply_sdss_preset_title",
		desc = "osa_apply_sdss_preset_desc",
		callback = "osa_callback_button",
		menu_id = "osa_options_menu",
		priority = -2,
		disabled = false,
	})
end)

function OSA:apply_sdss_preset_callback()
	local menu_title = managers.localization:text("osa_dialog_title")
	local menu_message = managers.localization:text("osa_dialog_apply_recommended")
	local menu_options = {
		{
			text = managers.localization:text("dialog_apply"),
			callback = function()
				for k, v in pairs(self.sdss_preset) do
					self.settings[k] = v
					--Don't refresh disabled options
					local item = ncUtils.Menu:get_item(k, self)
					if item and item:enabled() then
						ncUtils.Menu:set_item_value(k, v, self)
					end
				end
			end,
		},
		{
			text = managers.localization:text("dialog_cancel"),
			is_cancel_button = true,
			is_focused_button = true,
		},
	}
	QuickMenu:new(menu_title, menu_message, menu_options):Show()
end

function OSA:remove_custom_weapon_blueprints()
	local weapon_skins = tweak_data and tweak_data.blackmarket and tweak_data.blackmarket.weapon_skins
	for k, v in pairs(weapon_skins or {}) do
		if v.custom and v.default_blueprint then
			v._osa_custom_default_blueprint = v.default_blueprint
			v.default_blueprint = nil
		end
	end
end

function OSA:restore_custom_weapon_blueprints()
	local weapon_skins = tweak_data and tweak_data.blackmarket and tweak_data.blackmarket.weapon_skins
	for k, v in pairs(weapon_skins or {}) do
		if v.custom and v._osa_custom_default_blueprint then
			v.default_blueprint = v._osa_custom_default_blueprint
			v._osa_custom_default_blueprint = nil
		end
	end
end

function OSA:set_weapon_color_defaults(data)
	if self.settings.osa_color_wear > 1 then
		data.cosmetic_quality = ncUtils.Menu:get_multi_choice_suffix("osa_color_wear", self)
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
			menu_message = menu_message .. "\n - part_id: " .. part_id
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
			if not params.locked then
				menu_message = menu_message.."\n\n"..managers.localization:text("osa_dialog_choose_attachments")
			else
				menu_message = menu_message.."\n\n"..managers.localization:text("dialog_weapon_cosmetics_locked")
			end
		else
			menu_message = managers.localization:text("dialog_weapon_cosmetics_remove", {cosmetic = params.name})
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

--Simple menu
function OSA:weapon_cosmetics_handler_simple(params)
	local menu_title = managers.localization:text("osa_dialog_title")

	local menu_message
	if params.add then
		menu_message = managers.localization:text("dialog_weapon_cosmetics_add", {cosmetic = params.name})
		if not params.locked then
			menu_message = menu_message.."\n\n"..managers.localization:text("osa_dialog_autokeep")
		else
			menu_message = menu_message.."\n\n"..managers.localization:text("dialog_weapon_cosmetics_locked")
		end
	else
		menu_message = managers.localization:text("dialog_weapon_cosmetics_remove", {cosmetic = params.name})
		menu_message = menu_message.."\n\n"..managers.localization:text("osa_dialog_autokeep")
	end

	local menu_options = {
		{
			text = managers.localization:text("dialog_apply"),
			callback = function()
				self._mode = not params.locked and "keep" or "replace"
				params.yes_clbk()
			end,
			is_focused_button = true,
		},
		{
			text = managers.localization:text("dialog_cancel"),
			is_cancel_button = true,
		}
	}
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
			text = managers.localization:text("osa_color_wear_"..quality),
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
