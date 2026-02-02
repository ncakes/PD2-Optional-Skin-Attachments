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

function BlackMarketManager:osa_set_visible_parts()
	for skin_id, data in pairs(OSA.data.skins) do
		local has_skin = self:have_inventory_tradable_item("weapon_skins", skin_id)
		local show = OSA.settings.osa_gen1_support and (has_skin or not OSA.settings.osa_hide_unowned)
		for _, part_id in pairs(data.parts) do
			tweak_data.weapon.factory.parts[part_id].pcs = show and {} or nil
			tweak_data.weapon.factory.parts[part_id].inaccessible = not show
			tweak_data.blackmarket.weapon_mods[part_id].pcs = show and {} or nil
			tweak_data.blackmarket.weapon_mods[part_id].inaccessible = not show
		end
	end
end

--Includes special_blueprint. Returns {} if no skin_id or no blueprint.
local function get_skin_blueprint(weapon_id, skin_id)
	if skin_id and tweak_data.blackmarket.weapon_skins[skin_id] and tweak_data.blackmarket.weapon_skins[skin_id].default_blueprint then
		return managers.weapon_factory:get_cosmetics_blueprint_by_weapon_id(weapon_id, skin_id)
	else
		return {}
	end
end

--Based on BlackMarketGui:purchase_weapon_mod_callback
function BlackMarketManager:osa_buy_mod(part_id)
	if managers.custom_safehouse:unlocked() then
		local weapon_mod_tweak = tweak_data.weapon.factory.parts[part_id]
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

--Sort available and unavailable. Cosmetics is new skin data from func, can be nil for remove.
function BlackMarketManager:osa_check_keepable_attachments(category, slot, cosmetics)
	local crafted = self._global.crafted_items[category][slot]
	local weapon_id = crafted.weapon_id

	local old_skin_blueprint = get_skin_blueprint(weapon_id, crafted.cosmetics and crafted.cosmetics.id)
	local new_skin_blueprint = get_skin_blueprint(weapon_id, cosmetics and cosmetics.id)
	local vanilla_blueprint = managers.weapon_factory:get_default_blueprint_by_factory_id(crafted.factory_id)
	local current_blueprint = crafted.blueprint

	--AOLA switch blueprints here?

	local parts_tweak_data = tweak_data.weapon.factory.parts
	local available = {}
	local unavailable = {}
	local shopping_list = {}
	for _, part_id in pairs(current_blueprint) do
		local dlc = parts_tweak_data[part_id].dlc or "normal"

		if table.contains(vanilla_blueprint, part_id) then
			--Nothing. Default part.
		elseif table.contains(new_skin_blueprint, part_id) then
			--OK. On new skin.
			table.insert(available, part_id)
		elseif parts_tweak_data[part_id].is_legendary_part then
			--INVALID. Not on skin and legendary.
			table.insert(unavailable, part_id)
		elseif not table.contains(old_skin_blueprint, part_id) then
			--OK. This is your own part.
			table.insert(available, part_id)
		elseif dlc ~= "normal" and not managers.dlc:is_dlc_unlocked(dlc) then
			--INVALID. Not your part and missing DLC. Paid buckshot on {"m37_wwt", "m37_smosh"}
			if part_id ~= "wpn_fps_upg_a_custom" then
				table.insert(unavailable, part_id)
			elseif self:has_inventory_item("normal", "weapon_mods", "wpn_fps_upg_a_custom_free") then
				table.insert(available, "wpn_fps_upg_a_custom_free")
			elseif OSA.settings.osa_autobuy then
				table.insert(shopping_list, "wpn_fps_upg_a_custom_free")
			else
				table.insert(unavailable, part_id)
			end
		elseif self:has_inventory_item(dlc, "weapon_mods", part_id) then
			--OK. In stock.
			table.insert(available, part_id)
		elseif parts_tweak_data[part_id].is_a_unlockable then
			--INVALID. No stock + is_a_unlockable.
			table.insert(unavailable, part_id)
		elseif OSA.settings.osa_autobuy then
			table.insert(shopping_list, part_id)
		else
			table.insert(unavailable, part_id)
		end
	end

	--Try to buy with CC
	for _, part_id in pairs(shopping_list) do
		if self:osa_buy_mod(part_id) then
			table.insert(available, part_id)
		else
			table.insert(unavailable, part_id)
		end
	end

	return {available = available, unavailable = unavailable}
end

--Apply a list of parts
--Important: need to update skin before calling otherwise no_consume is wrong
function BlackMarketManager:osa_apply_parts_list(category, slot, parts_list)
	local crafted = self._global.crafted_items[category][slot]
	local weapon_id = crafted.weapon_id
	local skin_id = crafted.cosmetics and crafted.cosmetics.id or nil
	local skin_blueprint = skin_id and get_skin_blueprint(weapon_id, skin_id) or {}

	local parts_tweak_data = tweak_data.weapon.factory.parts
	local failed = {}

	for _, part_id in pairs(parts_list) do
		if managers.weapon_factory:can_add_part(crafted.factory_id, part_id, crafted.blueprint) == nil then
			local global_value = parts_tweak_data[part_id].dlc or "normal"
			local free_of_charge = true
			local no_consume = table.contains(skin_blueprint, part_id) or parts_tweak_data[part_id].is_a_unlockable or false
			local loading = true--This skips OMW, otherwise game crashes
			self:buy_and_modify_weapon(category, slot, global_value, part_id, free_of_charge, no_consume, loading)
		else
			table.insert(failed, part_id)
		end
	end

	return failed
end

--Note: removed skin does not use special blueprint in basegame.
function BlackMarketManager:_set_weapon_cosmetics(category, slot, cosmetics, update_weapon_unit)
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
	local old_cosmetic_default_blueprint = get_skin_blueprint(crafted.weapon_id, old_cosmetic_id)

	--Mode can be "keep", "replace", or "remove"
	local mode = OSA._mode or "keep"
	if mode == "replace" then
		self:add_crafted_weapon_blueprint_to_inventory(category, slot, old_cosmetic_default_blueprint)
		crafted.global_values = {}
		crafted.blueprint = get_skin_blueprint(crafted.weapon_id, cosmetics.id)
		if OSA.settings.osa_swap_buckshot and not weapon_skin_data.locked and managers.dlc:is_dlc_unlocked("gage_pack_shotgun") then
			--These are the only skins with free buckshot
			if table.contains({"ksg_same", "saiga_buck", "judge_burn", "boot_buck", "rota_ait", "serbu_lones"}, cosmetics.id) then
				for k, v in pairs(crafted.blueprint) do
					if v == "wpn_fps_upg_a_custom_free" then
						crafted.blueprint[k] = "wpn_fps_upg_a_custom"
						break
					end
				end
			end
		end
	elseif mode == "remove" then
		self:add_crafted_weapon_blueprint_to_inventory(category, slot, old_cosmetic_default_blueprint)
		crafted.global_values = {}
		crafted.blueprint = deep_clone(managers.weapon_factory:get_default_blueprint_by_factory_id(crafted.factory_id))
	else
		--Defaults to keep
		local reconstruct = self:osa_check_keepable_attachments(category, slot, cosmetics)
		self:add_crafted_weapon_blueprint_to_inventory(category, slot, old_cosmetic_default_blueprint)
		crafted.global_values = {}
		crafted.blueprint = deep_clone(managers.weapon_factory:get_default_blueprint_by_factory_id(crafted.factory_id))
		--Have to set it here so no_consume works correctly
		crafted.cosmetics = cosmetics
		local retry = self:osa_apply_parts_list(category, slot, reconstruct.available)
		local fail = self:osa_apply_parts_list(category, slot, retry)
		table.list_append(fail, reconstruct.unavailable)
		if OSA.settings.osa_show_failure and #fail > 0 and update_weapon_unit then
			OSA:failure_dialog(fail)
		end
	end
	OSA._mode = nil

	--Name only locked if skin locked
	crafted.customize_locked = weapon_skin_data.locked
	crafted.locked_name = weapon_skin_data.locked

	--Rest unchanged
	crafted.cosmetics = cosmetics
	if old_cosmetic_id then
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

function BlackMarketManager:on_remove_weapon_cosmetics(category, slot, skip_update)
	local crafted = self._global.crafted_items[category][slot]
	if not crafted then
		return
	end

	--Get old skin
	local old_cosmetic_id = crafted.cosmetics and crafted.cosmetics.id
	local old_cosmetic_data = old_cosmetic_id and tweak_data.blackmarket.weapon_skins[old_cosmetic_id]
	local old_cosmetic_default_blueprint = get_skin_blueprint(crafted.weapon_id, old_cosmetic_id)

	local mode = OSA._mode or "keep"
	if mode == "remove" then
		self:add_crafted_weapon_blueprint_to_inventory(category, slot, old_cosmetic_default_blueprint)
		crafted.global_values = {}
		crafted.blueprint = deep_clone(managers.weapon_factory:get_default_blueprint_by_factory_id(crafted.factory_id))
	else
		--Defaults to keep
		local reconstruct = self:osa_check_keepable_attachments(category, slot, nil)
		self:add_crafted_weapon_blueprint_to_inventory(category, slot, old_cosmetic_default_blueprint)
		crafted.global_values = {}
		crafted.blueprint = deep_clone(managers.weapon_factory:get_default_blueprint_by_factory_id(crafted.factory_id))
		--Have to set it here so no_consume works correctly
		crafted.cosmetics = nil
		local retry = self:osa_apply_parts_list(category, slot, reconstruct.available)
		local fail = self:osa_apply_parts_list(category, slot, retry)
		table.list_append(fail, reconstruct.unavailable)
		if OSA.settings.osa_show_failure and #fail > 0 and not skip_update then
			OSA:failure_dialog(fail)
		end
	end
	OSA._mode = nil

	--Remove GVs
	crafted.cosmetics = nil
	if old_cosmetic_id then
		local global_value = old_cosmetic_data.global_value or managers.dlc:dlc_to_global_value(old_cosmetic_data.dlc)
		self:alter_global_value_item(global_value, category, slot, old_cosmetic_id, CRAFT_REMOVE)
	end

	crafted.customize_locked = nil
	--Bugfix: locked name is not reset when skin is removed in base game
	crafted.locked_name = nil

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

--Always allow mods to be previewed on legendary skins
function BlackMarketManager:is_previewing_legendary_skin()
	return false
end

function BlackMarketManager:view_weapon_with_cosmetics(category, slot, cosmetics, open_node_cb, spawn_workbench, custom_data)
	if not self._global.crafted_items[category] or not self._global.crafted_items[category][slot] then
		return
	end
	local weapon = self._global.crafted_items[category][slot]
	local weapon_id = weapon.weapon_id
	local factory_id = weapon.factory_id
	--Deepclone here already
	local blueprint = self._preview_blueprint and self._preview_blueprint.blueprint or deep_clone(weapon.blueprint)
	local weapon_skin_data = tweak_data.blackmarket.weapon_skins[cosmetics.id]

	local mode = OSA._mode or "keep"
	if mode == "replace" then
		blueprint = get_skin_blueprint(weapon_id, cosmetics.id)
	elseif mode == "remove" then
		blueprint = deep_clone(managers.weapon_factory:get_default_blueprint_by_factory_id(factory_id))
	else
		--Nothing
	end

	--Don't set this so we can preview again
	--self._last_viewed_cosmetic_id = cosmetics.id

	self:get_preview_blueprint(category, slot)
	--Don't deep copy again
	self._preview_blueprint.blueprint = blueprint

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
--Tempfix: set special blueprint parts as unlockable so they don't get added
Hooks:PreHook(BlackMarketManager, "modify_weapon", "OSA-PreHook-BlackMarketManager:modify_weapon", function(self, category, slot, ...)
	local crafted = self._global.crafted_items[category] and self._global.crafted_items[category][slot]
	if crafted and crafted.cosmetics then
		local skin_data = tweak_data.blackmarket.weapon_skins[crafted.cosmetics.id]
		local special_blueprint = skin_data and skin_data.special_blueprint and skin_data.special_blueprint[crafted.weapon_id]
		if special_blueprint then
			crafted.global_values = crafted.global_values or {}
			--Important: this is the table that is checked
			local parts_tweak = tweak_data.blackmarket.weapon_mods
			for _, part_id in pairs(special_blueprint) do
				parts_tweak[part_id]._osa_sb_is_a_unlockable = parts_tweak[part_id].is_a_unlockable
				parts_tweak[part_id].is_a_unlockable = true
			end
		end
	end
end)
Hooks:PostHook(BlackMarketManager, "modify_weapon", "OSA-PostHook-BlackMarketManager:modify_weapon", function(self, category, slot, ...)
	local crafted = self._global.crafted_items[category] and self._global.crafted_items[category][slot]
	if crafted and crafted.cosmetics then
		local skin_data = tweak_data.blackmarket.weapon_skins[crafted.cosmetics.id]
		local special_blueprint = skin_data and skin_data.special_blueprint and skin_data.special_blueprint[crafted.weapon_id]
		if special_blueprint then
			crafted.global_values = crafted.global_values or {}
			--Important: this is the table that is checked
			local parts_tweak = tweak_data.blackmarket.weapon_mods
			for _, part_id in pairs(special_blueprint) do
				parts_tweak[part_id].is_a_unlockable = parts_tweak[part_id]._osa_sb_is_a_unlockable
			end
		end
	end
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
	-- U242+ uses suffix "<skin>_<weapon_id>" when the cosmetic isn't the skin's base weapon.
	-- The path has also moved from dlcs/<bundle_folder> to dlcs/cash/safes/<bundle_folder>
	-- Leaving this for custom weapon skins that are using the old path.
	local texture_path, rarity_path = orig_BlackMarketManager_get_weapon_icon_path(self, weapon_id, cosmetics)
	if texture_path and not DB:has(Idstring("texture"), Idstring(texture_path)) then
		if skin_data and not skin_data.is_a_color_skin then
			local guis_catalog = "guis/"
			local bundle_folder = skin_data.texture_bundle_folder
			if bundle_folder then
				guis_catalog = guis_catalog .. "dlcs/" .. tostring(bundle_folder) .. "/"
			end
			local fallback_path = guis_catalog .. "weapon_skins/" .. tostring(skin_id)
			if DB:has(Idstring("texture"), Idstring(fallback_path)) then
				texture_path = fallback_path
			end
		end
	end
	return texture_path, rarity_path
end
