_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

--Set up legendary parts
Hooks:PostHook(WeaponFactoryTweakData, "_init_legendary", "OSA-PostHook-WeaponFactoryTweakData:_init_legendary", function(self)
	--Fix Astatoz legendary foregrip type
	self.parts.wpn_fps_ass_m16_fg_legend.type = "foregrip"

	--Fix incorrect name_id, needed for localization
	self.parts.wpn_fps_pis_deagle_b_legend.name_id = "bm_wp_deagle_b_legend"
	self.parts.wpn_fps_fla_mk2_body_fierybeast.name_id = "bm_wp_fla_mk2_body_fierybeast"
	self.parts.wpn_fps_rpg7_m_grinclown.name_id = "bm_wp_rpg7_m_grinclown"
	self.parts.wpn_fps_shot_r870_s_legendary.name_id = "bm_wp_r870_s_legend"
	self.parts.wpn_fps_shot_r870_fg_legendary.name_id = "bm_wp_r870_fg_legend"
	self.parts.wpn_fps_snp_model70_b_legend.name_id = "bm_wp_model70_b_legend"
	self.parts.wpn_fps_snp_model70_s_legend.name_id = "bm_wp_model70_s_legend"

	for skin_id, data in pairs(OSA.legend_data) do
		for part_id, _ in pairs(data.parts) do
			--OSA tracking
			self.parts[part_id].is_legendary_part = true

			--Set unlockable so it can't be dropped/bought
			self.parts[part_id].is_a_unlockable = true

			--Add description
			self.parts[part_id].has_description = true
			self.parts[part_id].desc_id = "bm_req_legend_equipped_" .. skin_id

			--Set sub_type to "laser" so the color can be changed
			--Raven's barrel sub_type is "silencer" which is wrong, but it has a gadget so that gets overwritten here
			if self.parts[part_id].perks then
				if table.contains(self.parts[part_id].perks, "gadget") then
					self.parts[part_id].sub_type = "laser"
				end
			end
		end
	end
end)

--Set some adds/forbids to prevent legendary attachment clipping.
--Do not add or delete legendary mods from uses_parts, can cause sync issues/cheater tags.
Hooks:PreHook(WeaponFactoryTweakData, "_set_inaccessibles", "OSA-PreHook-WeaponFactoryTweakData:_set_inaccessibles", function(self)
	local function override_unit(part_id, change_part_id, unit)
		if not DB:has(Idstring("unit"), unit) then
			log("[OSA/AOLA] DB missing unit: " .. unit)
			return
		end

		if self.parts[part_id] then
			self.parts[part_id].override = self.parts[part_id].override or {}
			self.parts[part_id].override[change_part_id] = self.parts[part_id].override[change_part_id] or {}
			self.parts[part_id].override[change_part_id].unit = unit
		end
	end

	local function hide_part(part_id, hide_part_id)
		local unit = "units/payday2/weapons/wpn_upg_dummy/wpn_upg_dummy"
		override_unit(part_id, hide_part_id, unit)
	end

	--Safely add a value to the table of a part_id. Creates the table if it does not exist.
	--Does nothing if value==part_id or if the value is already in the table.
	local function wftd_safe_add_value(part_id, table_name, value)
		if value ~= part_id and self.parts[part_id] then
			self.parts[part_id][table_name] = self.parts[part_id][table_name] or {}
			if not table.contains(self.parts[part_id][table_name], value) then
				table.insert(self.parts[part_id][table_name], value)
			end
		end
	end

	--Big Kahuna. Legendary stock hides default grip.
	hide_part("wpn_fps_shot_r870_s_legendary", "wpn_fps_upg_m4_g_standard")

	--Demon. Legendary stock hides default grip.
	hide_part("wpn_fps_shot_shorty_s_legendary", "wpn_fps_upg_m4_g_standard")

	--Mars Ultor. Legendary barrel hides default barrel extension.
	hide_part("wpn_fps_ass_tecci_b_legend", "wpn_fps_ass_tecci_ns_standard")

	--Vlad's Rodina. Legendary stock adds default grip. Legendary grip forbids default grip
	wftd_safe_add_value("wpn_upg_ak_s_legend", "adds", "wpn_upg_ak_g_standard")
	wftd_safe_add_value("wpn_upg_ak_g_legend", "forbids", "wpn_upg_ak_g_standard")
	--Legendary grip forbids Wooden Sniper Stock
	wftd_safe_add_value("wpn_upg_ak_g_legend", "forbids", "wpn_upg_ak_s_psl")

	--Raven Admiral. Legendary barrel adds standard foregrip and forbids short foregrip.
	--Otherwise the foregrip disappears if you use the Short Barrel then switch to the Admiral Barrel.
	wftd_safe_add_value("wpn_fps_sho_ksg_b_legendary", "adds", "wpn_fps_sho_ksg_fg_standard")
	wftd_safe_add_value("wpn_fps_sho_ksg_b_legendary", "forbids", "wpn_fps_sho_ksg_fg_short")

	--Iron sights for the Midas Touch Barrel on the Akimbo Deagle.
	do
		self.wpn_fps_x_deagle.adds = self.wpn_fps_x_deagle.adds or {}
		self.wpn_fps_x_deagle.adds.wpn_fps_pis_deagle_b_legend = {
			"wpn_fps_pis_deagle_o_standard_rear",
			"wpn_fps_pis_deagle_o_standard_front",
		}
	end

	--Fix the misaligned barrel extension on the Anarcho Barrel (thanks AkiraDragunDaishiyu)
	self.parts.wpn_fps_pis_judge_b_legend.override = self.parts.wpn_fps_pis_judge_b_legend.override or {}
	for _, part_id in ipairs(self.wpn_fps_pis_judge.uses_parts) do
		if self.parts[part_id] and self.parts[part_id].type == "barrel_ext" then
			self.parts.wpn_fps_pis_judge_b_legend.override[part_id] = {
				parent = "barrel",
			}
		end
	end

	--Allow equipping suppressors with the Demon Barrel
	--Previously possible but was removed in U242.1
	self.parts.wpn_fps_shot_shorty_b_legendary.forbids = nil

	--Allow equipping Iron Sight with the Don Pastrami Barrel
	--Previously possible but was removed in U242
	self.parts.wpn_fps_snp_model70_b_legend.forbids = nil

	if _G.BeardLib then
		do
			--Alamo Dallas "hide" default barrel.
			--Can't use standard dummy because it messes up the barrel extensions.
			local unit = "units/aola/weapons/wpn_fps_smg_p90_pts/wpn_fps_smg_p90_b_short_dallas"
			override_unit("wpn_fps_smg_p90_b_legend", "wpn_fps_smg_p90_b_short", unit)
		end
		do
			--Don Pastrami suppressor fix
			local unit = "units/aola/weapons/wpn_fps_snp_model70_pts/wpn_fps_snp_model70_ns_suppressor_baaah"
			override_unit("wpn_fps_snp_model70_b_legend", "wpn_fps_snp_model70_ns_suppressor", unit)
		end
	end
end)
