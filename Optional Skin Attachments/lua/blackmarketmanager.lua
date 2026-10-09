_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

--Refresh parts after Steam inventory update.
Hooks:PostHook(BlackMarketManager, "tradable_update", "OSA-PostHook-BlackMarketManager:tradable_update", function(self, ...)
	self:osa_set_visible_parts()
end)

--Set parts on first load, only happens once.
--Needed because init_finalize gets called before this.
Hooks:PostHook(BlackMarketManager, "load", "OSA-PostHook-BlackMarketManager:load", function(self, ...)
	self:osa_set_visible_parts()
end)

--Set parts on reload. Needed because load is only called once.
Hooks:PostHook(BlackMarketManager, "init_finalize", "OSA-PostHook-BlackMarketManager:init_finalize", function(self, ...)
	self:osa_set_visible_parts()
end)

--Checks which skins are owned and set available legendary parts
function BlackMarketManager:osa_set_visible_parts()
	for skin_id, data in pairs(OSA.legend_data) do
		local has_skin = self:have_inventory_tradable_item("weapon_skins", skin_id)
		local show = OSA.settings.gen1_legend_support and (has_skin or not OSA.settings.hide_unowned_legend)
		for part_id, _ in pairs(data.parts) do
			tweak_data.weapon.factory.parts[part_id].pcs = show and {} or nil
			tweak_data.weapon.factory.parts[part_id].inaccessible = not show
			tweak_data.blackmarket.weapon_mods[part_id].pcs = show and {} or nil
			tweak_data.blackmarket.weapon_mods[part_id].inaccessible = not show
		end
	end
end

--Returns a copy that can be safely modified.
local function get_vanilla_blueprint_fid(factory_id)
	return deep_clone(managers.weapon_factory:get_default_blueprint_by_factory_id(factory_id))
end

local function get_vanilla_blueprint_wid(weapon_id)
	local factory_id = managers.weapon_factory:get_factory_id_by_weapon_id(weapon_id)
	return get_vanilla_blueprint_fid(factory_id)
end

--Returns a copy that includes special_blueprint if applicable.
--Returns nil if no skin_id or no default_blueprint.
--Adapted from WeaponFactoryManager:get_cosmetics_blueprint_by_weapon_id
--special_blueprint was added in U242 when they enabled single/akimbo switching.
--It's used for storing attachments which are only available on specific weapons.
local function get_skin_blueprint(weapon_id, skin_id)
	local skin_data = skin_id and tweak_data.blackmarket.weapon_skins[skin_id]
	if not skin_data or not skin_data.default_blueprint then
		return
	end

	--return managers.weapon_factory:get_cosmetics_blueprint_by_weapon_id(weapon_id, skin_id)

	--Hardcode, better compatibility and guaranteed to be a clone
	local blueprint = deep_clone(skin_data.default_blueprint)
	local special_blueprint = skin_data.special_blueprint and skin_data.special_blueprint[weapon_id] or {}
	table.list_append(blueprint, special_blueprint)
	return blueprint
end

local function get_part_global_value(part_id)
	local part_data = tweak_data.weapon.factory.parts[part_id]

	if not part_data then
		--We tried
		return
	end

	--Handle custom parts
	if part_data.custom then
		return part_data.global_value or "normal"
	end

	return part_data.dlc and managers.dlc:dlc_to_global_value(part_data.dlc) or "normal"
end

local function set_global_values(crafted)
	local factory_id = crafted and crafted.factory_id
	local vanilla_parts = factory_id and managers.weapon_factory:get_default_blueprint_by_factory_id(factory_id)
	if not vanilla_parts then
		return
	end

	crafted.global_values = {}
	for _, part_id in pairs(crafted.blueprint) do
		if not table.contains(vanilla_parts, part_id) then
			crafted.global_values[part_id] = get_part_global_value(part_id)
		end
	end
end

--Based on BlackMarketGui:purchase_weapon_mod_callback
--Only checks cost, make sure you are allowed to buy the mod before calling (not unlockable, dlc owned).
function BlackMarketManager:osa_buy_mod(part_id)
	if managers.custom_safehouse:unlocked() then
		local weapon_mod_tweak = tweak_data.weapon.factory.parts[part_id]
		--We should only need to buy base-game parts so this is fine
		local global_value = weapon_mod_tweak.dlc and managers.dlc:dlc_to_global_value(weapon_mod_tweak.dlc) or "normal"
		local prices = tweak_data.safehouse.prices
		local cc_cost = weapon_mod_tweak.is_event_mod and prices.event_weapon_mod or prices.weapon_mod

		local coins = managers.custom_safehouse:coins()
		if coins >= cc_cost then
			self:add_to_inventory(global_value, "weapon_mods", part_id, true)
			managers.custom_safehouse:deduct_coins(cc_cost)
			return true
		end
	end
	return false
end

--Apply a list of parts.
--Important: need to update skin before calling otherwise no_consume is wrong
function BlackMarketManager:osa_apply_parts_list(category, slot, parts_list, retry)
	local crafted = self._global.crafted_items[category][slot]
	local weapon_id = crafted.weapon_id
	local skin_id = crafted.cosmetics and crafted.cosmetics.id or nil
	local skin_blueprint = skin_id and get_skin_blueprint(weapon_id, skin_id) or {}

	local parts_tweak_data = tweak_data.weapon.factory.parts
	local failed = {}

	for _, part_id in pairs(parts_list) do
		if managers.weapon_factory:can_add_part(crafted.factory_id, part_id, crafted.blueprint) == nil then
			local global_value = get_part_global_value(part_id)
			local free_of_charge = true
			local no_consume = table.contains(skin_blueprint, part_id) or parts_tweak_data[part_id].is_a_unlockable or false
			local loading = true--This skips OMW, otherwise game crashes
			self:buy_and_modify_weapon(category, slot, global_value, part_id, free_of_charge, no_consume, loading)
		else
			table.insert(failed, part_id)
		end
	end

	--Do a second pass in case there are dependencies
	--e.g. maybe we tried to apply a Scope Mount before a scope.
	if #failed > 0 and retry then
		return self:osa_apply_parts_list(category, slot, failed, false)
	else
		return failed
	end
end

--New function for keeping attachments and switching cosmetics.
--Cosmetics can be nil, will remove.
--Returns a list of parts that could not be kept and whether the blueprint was modified.
--Parts list can be empty but blueprint can still be modified if autoswapping.
--FBMR compatibility: OSA needs to replace the blueprint table if any attachments were changed.
--If the table is not replaced, FBMR assumes that the blueprint is the same (vanilla game behavior).
function BlackMarketManager:osa_keep_attachments(category, slot, cosmetics)
	local crafted = self._global.crafted_items[category] and self._global.crafted_items[category][slot]
	set_global_values(crafted)

	local old_cosmetic_id = crafted.cosmetics and crafted.cosmetics.id
	local new_cosmetic_id = cosmetics and cosmetics.id
	--Same skin
	if old_cosmetic_id == new_cosmetic_id then
		crafted.cosmetics = cosmetics
		return {}
	end

	local old_cosmetic_default_blueprint = old_cosmetic_id and get_skin_blueprint(crafted.weapon_id, old_cosmetic_id) or {}
	local new_cosmetic_default_blueprint = new_cosmetic_id and get_skin_blueprint(crafted.weapon_id, new_cosmetic_id) or {}
	--No attachments in either blueprint
	if #old_cosmetic_default_blueprint == 0 and #new_cosmetic_default_blueprint == 0 then
		crafted.cosmetics = cosmetics
		return {}
	end

	--Well this could be annoying
	local parts_tweak_data = tweak_data.weapon.factory.parts
	local vanilla_blueprint = get_vanilla_blueprint_fid(crafted.factory_id)

	--Legendary autoswap. Modify current blueprint.
	if _G.AOLA and OSA.settings.autoswap_legend then
		--FBMR compatibility
		local blueprint_changed = false
		--AOLA 2.0+ will tag all AOLA parts, the key is specified in AOLA.config.part_tag
		local aola_tag = AOLA.config and AOLA.config.part_tag
		local aola_suffix = AOLA.config and AOLA.config.part_suffix or "_addon"
		--Returns nil if not an AOLA part, otherwise returns real part_id
		local function get_real_legend_part(part_id)
			local part_data = parts_tweak_data[part_id]
			if not part_data then
				return
			end
			local is_addon_part = aola_tag and part_data[aola_tag]
			--Only fall back to texture bundle folder if aola_tag not defined.
			--Also make sure the suffix matches.
			if not aola_tag then
				is_addon_part = (part_data.texture_bundle_folder == "aola") and ncUtils.String:tail_match(part_id, aola_suffix)
			end
			if is_addon_part then
				return ncUtils.String:strip_suffix(part_id, aola_suffix)
			end
		end

		--Removing a legendary skin.
		local old_legend_data = old_cosmetic_id and OSA.legend_data[old_cosmetic_id]

		--Adding a legendary skin.
		local new_legend_data = new_cosmetic_id and OSA.legend_data[new_cosmetic_id]

		--Legendary part must be part of the old skin because there's no other way to use it.
		if old_legend_data and table.contains(old_legend_data.weapons, crafted.weapon_id) then
			for i, part_id in ipairs(crafted.blueprint) do
				local new_part_id = parts_tweak_data[part_id].is_legendary_part and part_id..aola_suffix
				if new_part_id and parts_tweak_data[new_part_id] then
					crafted.blueprint[i] = new_part_id
					blueprint_changed = true
					if crafted.custom_colors and crafted.custom_colors[part_id] then
						crafted.custom_colors[new_part_id] = crafted.custom_colors[part_id]
					end
				end
			end
			set_global_values(crafted)
		end

		--In the future, if a weapon has more than one legendary skin with parts, we need to make sure the real part is included in the new legendary skin.
		--Currently not possible.
		if new_legend_data and table.contains(new_legend_data.weapons, crafted.weapon_id) then
			for i, part_id in ipairs(crafted.blueprint) do
				--Note: AOLA 2.1 adds extra legendary parts to Locomotive / Reinfeld.
				--These are tagged with part_data[aola_tag]=false and do not use the "_addon" suffix. Therefore they will not be detected by get_real_legend_part.
				local new_part_id = get_real_legend_part(part_id)
				if new_part_id and parts_tweak_data[new_part_id] then
					crafted.blueprint[i] = new_part_id
					blueprint_changed = true
					if crafted.custom_colors and crafted.custom_colors[part_id] then
						crafted.custom_colors[new_part_id] = crafted.custom_colors[part_id]
					end
				end
			end
			set_global_values(crafted)
		end

		--FBMR compatibility. Replace the crafted.blueprint table so FBMR knows attachments were changed.
		if blueprint_changed then
			crafted.blueprint = deep_clone(crafted.blueprint)
		end
	end

	--Array containing parts which could not be kept.
	local not_available = {}

	--Array containing parts for rebuild, only used if there were unavailable parts.
	local wanted_parts = {}
	--Table, k=part_id, v=global_value
	--If all parts are available, just manage inventory and continue.
	local take_from_inventory = {}
	local return_to_inventory = {}

	--Sort parts and try to buy missing parts
	for _, part_id in ipairs(crafted.blueprint) do
		if not table.contains(vanilla_blueprint, part_id) then
			local part_data = parts_tweak_data[part_id]
			local global_value = get_part_global_value(part_id)

			local in_old = table.contains(old_cosmetic_default_blueprint, part_id)
			local in_new = table.contains(new_cosmetic_default_blueprint, part_id)

			if in_old and not in_new then
				--We need to use our own part
				if self:has_inventory_item(global_value, "weapon_mods", part_id) then
					--We have it
					take_from_inventory[part_id] = global_value
				else
					--Check if we can buy it
					local legendary = part_data.is_legendary_part or part_data.unatainable
					local unlockable = part_data.is_a_unlockable
					local missing_dlc = not part_data.custom and part_data.dlc and not managers.dlc:is_dlc_unlocked(part_data.dlc)
					local can_buy = OSA.settings.autobuy_missing and not legendary and not unlockable and not missing_dlc
					if can_buy and self:osa_buy_mod(part_id) then
						take_from_inventory[part_id] = global_value
					else
						table.insert(not_available, part_id)
					end
				end
			elseif in_new and not in_old then
				--Use free
				return_to_inventory[part_id] = global_value
			else
				--Either in both skins, keep using free part.
				--Or in neither skin, keep using your own part.
				--Inventory management not needed but need to track in case a rebuild is required.
				table.insert(wanted_parts, part_id)
			end
		end
	end

	--Everything available, just update inventory
	if #not_available == 0 then
		for part_id, global_value in pairs(take_from_inventory) do
			if not parts_tweak_data[part_id].is_a_unlockable then
				self:remove_item(global_value, "weapon_mods", part_id)
				self:alter_global_value_item(global_value, "weapon_mods", slot, part_id, INV_REMOVE)
				self:alter_global_value_item(global_value, category, slot, part_id, CRAFT_ADD)
			end
		end
		for part_id, global_value in pairs(return_to_inventory) do
			if not parts_tweak_data[part_id].is_a_unlockable then
				self:add_to_inventory(global_value, "weapon_mods", part_id, true)
				self:alter_global_value_item(global_value, category, slot, part_id, CRAFT_REMOVE)
			end
		end
		crafted.cosmetics = cosmetics
		set_global_values(crafted)
		return {}
	end

	--Some parts unavailable, start with default blueprint and do a two-pass apply.
	--wanted_parts was initialized with parts in both or neither skin.
	--Add parts which require inventory management (take_from_inventory/return_to_inventory).
	--We let the base game scrap and rebuild the entire gun, so no manual inventory management is required.
	for part_id, _ in pairs(take_from_inventory) do
		table.insert(wanted_parts, part_id)
	end
	for part_id, _ in pairs(return_to_inventory) do
		table.insert(wanted_parts, part_id)
	end

	--Return to inventory and reset blueprint.
	--vanilla_blueprint is already a clone and we didn't modify it, just use directly.
	self:add_crafted_weapon_blueprint_to_inventory(category, slot, old_cosmetic_default_blueprint)
	crafted.blueprint = vanilla_blueprint
	crafted.global_values = {}

	--Set cosmetics before applying new parts list
	crafted.cosmetics = cosmetics
	local failed = self:osa_apply_parts_list(category, slot, wanted_parts, true)
	table.list_append(not_available, failed)
	set_global_values(crafted)
	return not_available
end

--Note: removed skin does not use special blueprint in basegame.
local orig_BlackMarketManager__set_weapon_cosmetics = BlackMarketManager._set_weapon_cosmetics
function BlackMarketManager:_set_weapon_cosmetics(...)
	local mode = OSA._mode
	if not mode then
		--I'm not touching this
		return orig_BlackMarketManager__set_weapon_cosmetics(self, ...)
	end
	OSA._mode = nil
	return self:osa_set_weapon_cosmetics(mode, ...)
end

function BlackMarketManager:osa_set_weapon_cosmetics(mode, category, slot, cosmetics, update_weapon_unit)
	local crafted = self._global.crafted_items[category] and self._global.crafted_items[category][slot]
	if not crafted then
		return
	end
	if not self:weapon_cosmetics_type_check(crafted.weapon_id, cosmetics.id) then
		return
	end
	local weapon_skin_data = tweak_data.blackmarket.weapon_skins[cosmetics.id]
	if not weapon_skin_data then
		return
	end

	--Get old skin
	--Bugfix: base game doesn't use special blueprint for old skin
	local old_cosmetic_id = crafted.cosmetics and crafted.cosmetics.id
	local old_cosmetic_data = old_cosmetic_id and tweak_data.blackmarket.weapon_skins[old_cosmetic_id]
	local old_cosmetic_default_blueprint = get_skin_blueprint(crafted.weapon_id, old_cosmetic_id) or {}

	--Mode is either "keep", "replace", or "remove"
	--FBMR compatibility: OSA needs to replace the blueprint table if any attachments were changed.
	--If the table is not replaced, FBMR assumes that the blueprint is the same (vanilla game behavior).
	if mode == "replace" then
		set_global_values(crafted)
		self:add_crafted_weapon_blueprint_to_inventory(category, slot, old_cosmetic_default_blueprint)
		crafted.blueprint = get_skin_blueprint(crafted.weapon_id, cosmetics.id) or get_vanilla_blueprint_fid(crafted.factory_id)
		crafted.cosmetics = cosmetics
		set_global_values(crafted)
	elseif mode == "remove" then
		set_global_values(crafted)
		self:add_crafted_weapon_blueprint_to_inventory(category, slot, old_cosmetic_default_blueprint)
		crafted.blueprint = get_vanilla_blueprint_fid(crafted.factory_id)
		crafted.cosmetics = cosmetics
		crafted.global_values = {}
	else
		--Defaults to keep
		local failed = self:osa_keep_attachments(category, slot, cosmetics)
		if #failed > 0 and update_weapon_unit and OSA.settings.show_failure then
			OSA:failure_dialog(failed)
		end
	end

	--Never lock names now that we have partial legendary customization natively
	crafted.customize_locked = weapon_skin_data.locked
	crafted.locked_name = nil

	if update_weapon_unit and OSA.settings.auto_clear_preview then
		self:clear_preview_blueprint()
	end

	--Rest unchanged except for old_cosmetic_data crashguard
	if old_cosmetic_id and old_cosmetic_data then
		local global_value = old_cosmetic_data.global_value or managers.dlc:dlc_to_global_value(old_cosmetic_data.dlc)
		self:alter_global_value_item(global_value, category, slot, old_cosmetic_id, CRAFT_REMOVE)
	end
	if cosmetics.id then
		local global_value = weapon_skin_data.global_value or managers.dlc:dlc_to_global_value(weapon_skin_data.dlc)
		self:alter_global_value_item(global_value, category, slot, cosmetics.id, CRAFT_ADD)
	end
	if update_weapon_unit and managers.menu_scene then
		local data = category == "primaries" and self:equipped_primary() or self:equipped_secondary()
		if data then
			managers.menu_scene:set_character_equipped_weapon(nil, data.factory_id, data.blueprint, category == "primaries" and "primary" or "secondary", data.cosmetics)
			if managers.menu_scene:get_current_scene_template() == "blackmarket_crafting" then
				self:view_weapon(category, slot, function ()
				end, nil, BlackMarketGui.get_crafting_custom_data())
			end
		end
	end
	MenuCallbackHandler:_update_outfit_information()
end

local orig_BlackMarketManager_on_remove_weapon_cosmetics = BlackMarketManager.on_remove_weapon_cosmetics
function BlackMarketManager:on_remove_weapon_cosmetics(...)
	local mode = OSA._mode
	if not mode then
		--I'm not touching this
		orig_BlackMarketManager_on_remove_weapon_cosmetics(self, ...)
		return
	end
	OSA._mode = nil
	return self:osa_on_remove_weapon_cosmetics(mode, ...)
end

function BlackMarketManager:osa_on_remove_weapon_cosmetics(mode, category, slot, skip_update)
	local crafted = self._global.crafted_items[category] and self._global.crafted_items[category][slot]
	if not crafted then
		return
	end

	--Get old skin
	local old_cosmetic_id = crafted.cosmetics and crafted.cosmetics.id
	local old_cosmetic_data = old_cosmetic_id and tweak_data.blackmarket.weapon_skins[old_cosmetic_id]
	local old_cosmetic_default_blueprint = get_skin_blueprint(crafted.weapon_id, old_cosmetic_id) or {}

	--Mode is either "keep" or "remove"
	if mode == "remove" then
		set_global_values(crafted)
		self:add_crafted_weapon_blueprint_to_inventory(category, slot, old_cosmetic_default_blueprint)
		crafted.blueprint = get_vanilla_blueprint_fid(crafted.factory_id)
		crafted.cosmetics = nil
		crafted.global_values = {}
	else
		--Defaults to keep
		local failed = self:osa_keep_attachments(category, slot, nil)
		if #failed > 0 and not skip_update and OSA.settings.show_failure then
			OSA:failure_dialog(failed)
		end
	end

	--Bugfix: locked name is not reset when skin is removed in base game.
	crafted.customize_locked = nil
	crafted.locked_name = nil

	--old_cosmetic_data crashguard
	if old_cosmetic_id and old_cosmetic_data then
		local global_value = old_cosmetic_data.global_value or managers.dlc:dlc_to_global_value(old_cosmetic_data.dlc)
		self:alter_global_value_item(global_value, category, slot, old_cosmetic_id, CRAFT_REMOVE)
	end

	if not skip_update and OSA.settings.auto_clear_preview then
		self:clear_preview_blueprint()
	end

	--Rest unchanged
	self:_verfify_equipped_category(category)
	if not skip_update then
		if managers.menu_scene then
			local data = category == "primaries" and self:equipped_primary() or self:equipped_secondary()
			if data then
				managers.menu_scene:set_character_equipped_weapon(nil, data.factory_id, data.blueprint, category == "primaries" and "primary" or "secondary", data.cosmetics)
				if managers.menu_scene:get_current_scene_template() == "blackmarket_crafting" then
					self:view_weapon(category, slot, function ()
					end, nil, BlackMarketGui.get_crafting_custom_data())
				end
			end
		end
		MenuCallbackHandler:_update_outfit_information()
	end
end

function BlackMarketManager:view_weapon_with_cosmetics(category, slot, cosmetics, open_node_cb, spawn_workbench, custom_data)
	--Previews are always manually initiated so this is fine
	local mode = OSA._mode or "keep"
	OSA._mode = nil

	if not self._global.crafted_items[category] or not self._global.crafted_items[category][slot] then
		return
	end
	local weapon = self._global.crafted_items[category][slot]
	local weapon_id = weapon.weapon_id
	local factory_id = weapon.factory_id

	--Initialize preview blueprint if not already
	self:get_preview_blueprint(category, slot)

	if mode == "replace" then
		self._preview_blueprint.blueprint = get_skin_blueprint(weapon_id, cosmetics.id) or get_vanilla_blueprint_fid(factory_id)
	elseif mode == "remove" then
		self._preview_blueprint.blueprint = get_vanilla_blueprint_fid(factory_id)
	else
		--Nothing, initialize already uses current weapon blueprint.
		--We clear the preview when changes are made to the real gun so it will be re-initialized.
	end

	--Don't set this so we can preview again
	--Note: this makes BlackMarketManager:is_previewing_legendary_skin always return false.
	--self._last_viewed_cosmetic_id = cosmetics.id

	local blueprint = self._preview_blueprint.blueprint
	--Rest unchanged
	self:set_preview_cosmetics(category, slot, cosmetics)
	local texture_switches = self:get_weapon_texture_switches(category, slot, weapon)
	self:preload_weapon_blueprint("preview", factory_id, blueprint, spawn_workbench)
	if spawn_workbench then
		table.insert(self._preloading_list, {
			done_cb = function ()
				managers.menu_scene:spawn_workbench_room()
			end
		})
	end
	table.insert(self._preloading_list, {
		done_cb = function ()
			managers.menu_scene:spawn_item_weapon(factory_id, blueprint, cosmetics, texture_switches, custom_data)
		end
	})
	table.insert(self._preloading_list, {
		done_cb = open_node_cb
	})
end

--This function doesn't check special blueprint in the base game so special blueprint parts are added to inventory.
--Tempfix: set special blueprint parts as unlockable so they don't get added.
--Still broken as of U248
Hooks:PreHook(BlackMarketManager, "modify_weapon", "OSA-PreHook-BlackMarketManager:modify_weapon", function(self, category, slot, ...)
	local crafted = self._global.crafted_items[category] and self._global.crafted_items[category][slot]
	if crafted and crafted.cosmetics then
		local skin_data = tweak_data.blackmarket.weapon_skins[crafted.cosmetics.id]
		local special_blueprint = skin_data and skin_data.special_blueprint and skin_data.special_blueprint[crafted.weapon_id]
		if special_blueprint then
			--Reference so we can revert after
			OSA._revert_special_blueprint = special_blueprint
			--Important: this is the table that is checked
			local parts_tweak = tweak_data.blackmarket.weapon_mods
			for _, part_id in pairs(special_blueprint) do
				parts_tweak[part_id]._osa_sb_is_a_unlockable = parts_tweak[part_id].is_a_unlockable
				parts_tweak[part_id].is_a_unlockable = true
			end
		end
	end
end)
Hooks:PostHook(BlackMarketManager, "modify_weapon", "OSA-PostHook-BlackMarketManager:modify_weapon", function(self, category, slot, global_value, part_id, remove_part, loading)
	--Clear preview blueprint
	if not loading and OSA.settings.auto_clear_preview then
		self:clear_preview_blueprint()
	end

	--Revert tempfix
	if OSA._revert_special_blueprint then
		local parts_tweak = tweak_data.blackmarket.weapon_mods
		for _, part_id in pairs(OSA._revert_special_blueprint) do
			parts_tweak[part_id].is_a_unlockable = parts_tweak[part_id]._osa_sb_is_a_unlockable
			parts_tweak[part_id]._osa_sb_is_a_unlockable = nil
		end
	end
	OSA._revert_special_blueprint = nil
end)

if _G.SDSS then
	return
end

--Put the default weapon icon over the rarity background for swapped skins to see what SDSS players are using
local orig_BlackMarketManager_get_weapon_icon_path = BlackMarketManager.get_weapon_icon_path
function BlackMarketManager:get_weapon_icon_path(weapon_id, cosmetics)
	local skin_id = cosmetics and cosmetics.id
	local skin_data = skin_id and tweak_data.blackmarket.weapon_skins[skin_id]

	if skin_data and not skin_data.is_a_color_skin and not self:weapon_cosmetics_type_check(weapon_id, skin_id) then
		local rarity = skin_data.rarity or "common"
		local rarity_path = tweak_data.economy.rarities[rarity] and tweak_data.economy.rarities[rarity].bg_texture
		local texture_path, _ = orig_BlackMarketManager_get_weapon_icon_path(self, weapon_id, nil)
		return texture_path, rarity_path
	end

	return orig_BlackMarketManager_get_weapon_icon_path(self, weapon_id, cosmetics)
end
