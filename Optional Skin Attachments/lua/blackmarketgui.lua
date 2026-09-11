--Add mod icons to legendary parts if not using BeardLib.
if not _G.BeardLib then
	Hooks:PostHook(BlackMarketGui, "populate_mods", "OSA-PostHook-BlackMarketGui:populate_mods", function(self, data)
		local weapon_id = data.prev_node_data and data.prev_node_data.name
		if not weapon_id then
			return
		end

		local skin_id
		for k, v in pairs(OSA.legend_data) do
			if table.contains(v.weapons, weapon_id) then
				skin_id = k
				break
			end
		end

		if skin_id then
			local parts_tweak_data = tweak_data.weapon.factory.parts
			for _, part in ipairs(data) do
				local part_id = part.name
				if part_id and parts_tweak_data[part_id] and parts_tweak_data[part_id].is_legendary_part then
					part.bitmap_texture = OSA.legend_data[skin_id].icon
				end
			end
		end
	end)
end

--Hijack skin apply/remove
function BlackMarketGui:_weapon_cosmetics_callback(data, add, yes_clbk)
	local params = {
		add = add,
		name = data.name_localized,
		yes_clbk = yes_clbk,
	}

	if add then
		local skin_id = data.cosmetic_id
		local skin_tweak = tweak_data.blackmarket.weapon_skins[skin_id]
		local has_blueprint = skin_tweak.default_blueprint and true or false

		local weapon_id = managers.blackmarket:get_crafted_category(data.category)[data.slot].weapon_id
		local correct_weapon = (skin_tweak.weapon_id == weapon_id) or (skin_tweak.weapon_ids and table.contains(skin_tweak.weapon_ids, weapon_id))

		params.locked = data.locked_cosmetics
		params.can_use_blueprint = has_blueprint and correct_weapon
	end

	if OSA.settings.always_keep then
		OSA:weapon_cosmetics_handler_simple(params)
	else
		OSA:weapon_cosmetics_handler(params)
	end
end

--Custom color settings
Hooks:PreHook(BlackMarketGui, "equip_weapon_color_callback", "OSA-PreHook-BlackMarketGui:equip_weapon_color_callback", function(self, data)
	if data.is_a_color_skin then
		OSA:set_weapon_color_defaults(data)
	end
end)

--Hijack preview and open our menu if preview is enabled
local orig_BlackMarketGui_preview_cosmetic_on_weapon_callback = BlackMarketGui.preview_cosmetic_on_weapon_callback
function BlackMarketGui:preview_cosmetic_on_weapon_callback(data)
	if not data._osa_done then
		--Set defaults for weapon color
		if data.is_a_color_skin then
			OSA:set_weapon_color_defaults(data)
		end

		local skin_id = data.cosmetic_id
		local skin_tweak = tweak_data.blackmarket.weapon_skins[skin_id]
		local has_blueprint = skin_tweak.default_blueprint and true or false

		local weapon_id = managers.blackmarket:get_crafted_category(data.category)[data.slot].weapon_id
		local correct_weapon = (skin_tweak.weapon_id == weapon_id) or (skin_tweak.weapon_ids and table.contains(skin_tweak.weapon_ids, weapon_id))

		--First choose wear, then choose attachment
		local preview_mode = ncUtils.Menu:get_multi_choice_suffix("osa_preview_mode", OSA)
		if preview_mode ~= "auto" then
			OSA:preview_wear_handler({
				choose_wear = table.contains({"wear", "both"}, preview_mode),
				choose_mods = table.contains({"mods", "both"}, preview_mode),
				data = data,
				can_use_blueprint = has_blueprint and correct_weapon,
			})
			return
		else
			OSA._mode = "keep"
		end
	end

	orig_BlackMarketGui_preview_cosmetic_on_weapon_callback(self, data)
	data._osa_done = nil
end

if _G.SDSS then
	return
end

--Fixed default sorting, from SDSS
Hooks:PostHook(BlackMarketGui, "populate_weapon_cosmetics", "OSA-PostHook-BlackMarketGui:populate_weapon_cosmetics", function(self, data, ...)
	local crafted = managers.blackmarket:get_crafted_category(data.category)[data.prev_node_data and data.prev_node_data.slot]
	local weapon_id = crafted.weapon_id

	--Get non-empty cells
	local sort_list = {}
	for _, v in ipairs(data) do
		if v.name ~= "empty" then
			table.insert(sort_list, v)
		end
	end

	--Apply a sort
	local td = tweak_data.blackmarket.weapon_skins
	local rtd = tweak_data.economy.rarities
	local etd = tweak_data.economy.qualities
	for _, v in ipairs(sort_list) do
		local skin_data = td[v.cosmetic_id]
		v.sort_keys = {
			color = v.is_a_color_skin and 0 or 1,
			unlocked = v.unlocked and 0 or 1,
			--rarity = 0,
			name = managers.localization:text(skin_data.name_id),
			skin_id = v.cosmetic_id,
			--Should only matter if not using HideDupeSkins
			wear = -etd[v.cosmetic_quality or "mint"].index,
			bonus = v.cosmetic_bonus and 0 or 1,
		}
		--Unlocked skins sort low-high rarity, locked skins high-low
		if v.unlocked then
			v.sort_keys.rarity = rtd[skin_data.rarity or "common"].index
		elseif not v.unlocked then
			v.sort_keys.rarity = -rtd[skin_data.rarity or "common"].index
		end
	end

	local sort_order = {
		"color", "unlocked", "rarity",
		"name", "skin_id",
		"wear", "bonus"
	}
	local x_keys, y_keys = nil
	local function sort_func(x, y)
		x_keys = x.sort_keys
		y_keys = y.sort_keys
		for _, k in ipairs(sort_order) do
			if x_keys[k] ~= y_keys[k] then
				return x_keys[k] < y_keys[k]
			end
		end
		return x.cosmetic_id < y.cosmetic_id
	end
	table.sort(sort_list, sort_func)

	--Iterate over data table, update visible items with the sorted one (or nil for hidden ones)
	for k, _ in ipairs(data) do
		data[k] = sort_list[k]
	end

	--Compatibility with Multiple Weapon Mod Rows
	--Need to pad with empties
	local cols = data.override_slots[1]
	local rows = data.override_slots[2]
	local n_fully_fill = cols * math.max(math.ceil(#data / cols), rows)
	for i = #data + 1, n_fully_fill do
		local new_data = {
			name = "empty",
			name_localized = "",
			category = data.category,
			slot = i,
			unlocked = true,
			equipped = false
		}
		data[i] = new_data
	end
end)
