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
		for part_id, legend_part_name_type in pairs(data.parts) do
			--OSA tracking
			self.parts[part_id].is_legendary_part = true

			--Set unlockable so it can't be dropped/bought
			self.parts[part_id].is_a_unlockable = true

			--Add description
			self.parts[part_id].has_description = true
			self.parts[part_id].desc_id = "bm_req_legend_equipped_" .. skin_id

			--Used to generate legendary attachment name
			self.parts[part_id].legend_part_name_type = legend_part_name_type

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

	--Big Kahuna / Demon
	--Default body adds default grip, legendary stock forbids default grip
	wftd_safe_add_value("wpn_fps_shot_r870_body_standard", "adds", "wpn_fps_upg_m4_g_standard")
	wftd_safe_add_value("wpn_fps_shot_r870_s_legendary", "forbids", "wpn_fps_upg_m4_g_standard")
	wftd_safe_add_value("wpn_fps_shot_shorty_s_legendary", "forbids", "wpn_fps_upg_m4_g_standard")
	--Reinfeld and Locomotive grips forbid default grip
	for _, part_id in pairs(self.wpn_fps_shot_r870.uses_parts) do
		if self.parts[part_id] and self.parts[part_id].type == "grip" then
			wftd_safe_add_value(part_id, "forbids", "wpn_fps_upg_m4_g_standard")
		end
	end
	for _, part_id in pairs(self.wpn_fps_shot_serbu.uses_parts) do
		if self.parts[part_id] and self.parts[part_id].type == "grip" then
			wftd_safe_add_value(part_id, "forbids", "wpn_fps_upg_m4_g_standard")
		end
	end

	--Mars Ultor
	--Default lower receiver adds default barrel extension, legendary barrel forbids default barrel extension
	wftd_safe_add_value("wpn_fps_ass_tecci_lower_reciever", "adds", "wpn_fps_ass_tecci_ns_standard")
	wftd_safe_add_value("wpn_fps_ass_tecci_b_legend", "forbids", "wpn_fps_ass_tecci_ns_standard")
	--Bootleg barrel extensions forbid default barrel extension
	for _, part_id in pairs(self.wpn_fps_ass_tecci.uses_parts) do
		if self.parts[part_id] and self.parts[part_id].type == "barrel_ext" then
			wftd_safe_add_value(part_id, "forbids", "wpn_fps_ass_tecci_ns_standard")
		end
	end

	--Vlad's Rodina
	--Legendary stock adds default grip, legendary grip forbids default grip
	wftd_safe_add_value("wpn_upg_ak_s_legend", "adds", "wpn_upg_ak_g_standard")
	wftd_safe_add_value("wpn_upg_ak_g_legend", "forbids", "wpn_upg_ak_g_standard")

	--Raven Admiral
	--Without this, the foregrip will disappear if you apply the Short Barrel then switch to the Admiral Barrel
	wftd_safe_add_value("wpn_fps_sho_ksg_b_legendary", "adds", "wpn_fps_sho_ksg_fg_standard")
	wftd_safe_add_value("wpn_fps_sho_ksg_b_legendary", "forbids", "wpn_fps_sho_ksg_fg_short")

	--Santa's Slayers Laser on single-hand Crosskill
	--Previously only available in AOLA but legendary attachments were added to the single-hand Crosskill in U242
	--Laser blocks all sights except for Marksman Sight to prevent clipping
	local whitelist = {"wpn_upg_o_marksmansight_rear"}
	for _, part_id in pairs(self.wpn_fps_pis_1911.uses_parts) do
		if not table.contains(whitelist, part_id) then
			if self.parts[part_id] and self.parts[part_id].type == "sight" then
				wftd_safe_add_value("wpn_fps_pis_1911_fl_legendary", "forbids", part_id)
			end
		end
	end

	--Allow the Demon Barrel to use suppressors
	--Previously possible but was removed from the game in U242.1
	self.parts.wpn_fps_shot_shorty_b_legendary.forbids = nil

	--Don Pastrami suppressor fix
	if _G.BeardLib then
		self.parts.wpn_fps_snp_model70_b_legend.override = self.parts.wpn_fps_snp_model70_b_legend.override or {}
		self.parts.wpn_fps_snp_model70_b_legend.override.wpn_fps_snp_model70_ns_suppressor = {
			third_unit = self.parts.wpn_fps_snp_model70_ns_suppressor.third_unit,
			unit = "units/aola/weapons/wpn_fps_snp_model70_pts/wpn_fps_snp_model70_ns_suppressor_addon",
		}
	end
end)
