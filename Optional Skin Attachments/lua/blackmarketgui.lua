_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

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

--Fixed default sorting, adapted from SDSS
local function post_populate_weapon_cosmetics(data)
	if #data < 1 then
		return
	end

	local rarity_indexes = {
		common = 1,
		uncommon = 2,
		rare = 3,
		epic = 4,
		legendary = 5,
	}

	local quality_indexes = {
		poor = 1,
		fair = 2,
		good = 3,
		fine = 4,
		mint = 5,
	}

	for _, v in ipairs(data) do
		local is_empty = (v.name == "empty")
		local rarity_index = rarity_indexes[v.cosmetic_rarity or "common"]
		local quality_index = quality_indexes[v.cosmetic_quality or "mint"]
		local bonus_index = v.cosmetic_bonus and 1 or 0

		local sort_keys = {
			empty = is_empty and 1 or 0,--Empty always last.
			color = v.is_a_color_skin and 0 or 1,--Color always first.
			unlocked = v.unlocked and 0 or 1,--Unlocked before locked.
			rarity = v.unlocked and rarity_index or -rarity_index,--lowhigh for unlocked, highlow for locked
			name = v.name_localized or "",
			skin_id = v.cosmetic_id or "",
			quality = -quality_index,
			bonus = -bonus_index,
		}

		v.sort_keys = sort_keys
	end

	local sort_order = {
		"empty", "color", "unlocked",
		"rarity", "name", "skin_id",
		"quality", "bonus"
	}

	local function sort_func(x, y)
		local x_keys = x.sort_keys
		local y_keys = y.sort_keys
		for _, k in ipairs(sort_order) do
			if x_keys[k] ~= y_keys[k] then
				return x_keys[k] < y_keys[k]
			end
		end
		return x.name < y.name
	end

	table.sort(data, sort_func)
end

Hooks:PreHook(BlackMarketGuiTabItem, "init", "OSA-PreHook-BlackMarketGuiTabItem:init", function(self, main_panel, data, ...)
	if data.name ~= "weapon_cosmetics" then
		return
	end

	--Should fix compatibility with mods that fully overwrite BMG:populate_weapon_cosmetics.
	local populate_func = data.on_create_func
	data.on_create_func = function(data, ...)
		populate_func(data, ...)
		post_populate_weapon_cosmetics(data)
	end
end)
