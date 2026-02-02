--Set some adds/forbids to prevent legendary attachment clipping.
--Do not add or delete legendary mods from uses_parts, can cause sync issues/cheater tags.
Hooks:PostHook(WeaponFactoryTweakData, "init", "OSA-PostHook-WeaponFactoryTweakData:init", function(self)
	local function safe_add_value(part_id, table_name, value)
		if value ~= part_id and self.parts[part_id] then
			self.parts[part_id][table_name] = self.parts[part_id][table_name] or {}
			if not table.contains(self.parts[part_id][table_name], value) then
				table.insert(self.parts[part_id][table_name], value)
			end
		end
	end

	--Big Kahuna / Demon
	--Default body adds default grip
	safe_add_value("wpn_fps_shot_r870_body_standard", "adds", "wpn_fps_upg_m4_g_standard")

	--Reinfeld and Locomotive grips forbid default grip
	for _, part_id in pairs(self.wpn_fps_shot_r870.uses_parts) do
		if self.parts[part_id] and self.parts[part_id].type == "grip" then
			safe_add_value(part_id, "forbids", "wpn_fps_upg_m4_g_standard")
		end
	end
	for _, part_id in pairs(self.wpn_fps_shot_serbu.uses_parts) do
		if self.parts[part_id] and self.parts[part_id].type == "grip" then
			safe_add_value(part_id, "forbids", "wpn_fps_upg_m4_g_standard")
		end
	end

	--Mars Ultor
	--Default lower receiver adds default barrel extension
	safe_add_value("wpn_fps_ass_tecci_lower_reciever", "adds", "wpn_fps_ass_tecci_ns_standard")

	--Bootleg barrel extensions forbid default barrel extension
	for _, part_id in pairs(self.wpn_fps_ass_tecci.uses_parts) do
		if self.parts[part_id] and self.parts[part_id].type == "barrel_ext" then
			safe_add_value(part_id, "forbids", "wpn_fps_ass_tecci_ns_standard")
		end
	end

	--Midas Touch
	--Stop barrel from shifting the front post of the Marksman Sight
	--Fixed in base game in U242 (and bricked OSA)
	--self.parts.wpn_fps_pis_deagle_b_legend.override.wpn_upg_o_marksmansight_front = nil

	--Santa's Slayers Laser on single-hand Crosskill
	--Previously only available in AOLA but legendary attachments were added to the single-hand Crosskill in U242
	local whitelist = {"wpn_upg_o_marksmansight_rear"}
	for _, part_id in pairs(self.wpn_fps_pis_1911.uses_parts) do
		if not table.contains(whitelist, part_id) then
			if self.parts[part_id] and self.parts[part_id].type == "sight" then
				safe_add_value("wpn_fps_pis_1911_fl_legendary", "forbids", part_id)
			end
		end
	end
end)

--Set up legendary parts, do it here so AOLA can copy.
Hooks:PostHook(WeaponFactoryTweakData, "_init_legendary", "OSA-PostHook-WeaponFactoryTweakData:_init_legendary", function(self)
	local function safe_add_value(part_id, table_name, value)
		if self.parts[part_id] and value ~= part_id then
			self.parts[part_id][table_name] = self.parts[part_id][table_name] or {}
			if not table.contains(self.parts[part_id][table_name], value) then
				table.insert(self.parts[part_id][table_name], value)
			end
		end
	end

	--Set up legendary parts
	local new_values = {
		is_a_unlockable = true,--Set unlockable so it can't be dropped/bought
		is_legendary_part = true,--OSA tracking
		has_description = true--So that we can set custom descriptions
	}

	--Set new values, set description
	for skin, data in pairs(OSA.data.skins) do
		for _, part_id in pairs(data.parts) do
			--Set new values
			for k, v in pairs(new_values) do
				self.parts[part_id][k] = v
			end

			--Set description
			self.parts[part_id].desc_id = "bm_req_"..skin.."_osa_desc"

			--Set sub_type to "laser" so the color can be changed
			if self.parts[part_id].perks then
				if table.contains(self.parts[part_id].perks, "gadget") then
					self.parts[part_id].sub_type = "laser"
				end
			end
			--Raven's barrel sub_type is "silencer" which is wrong, but it has a gadget so that gets overwritten here
		end
	end

	--Fix incorrect name_ids
	self.parts.wpn_fps_pis_deagle_b_legend.name_id = "bm_wp_deagle_b_legend"
	self.parts.wpn_fps_fla_mk2_body_fierybeast.name_id = "bm_wp_fla_mk2_body_fierybeast"
	self.parts.wpn_fps_rpg7_m_grinclown.name_id = "bm_wp_rpg7_m_grinclown"
	self.parts.wpn_fps_shot_r870_s_legendary.name_id = "bm_wp_r870_s_legend"
	self.parts.wpn_fps_shot_r870_fg_legendary.name_id = "bm_wp_r870_fg_legend"
	self.parts.wpn_fps_snp_model70_b_legend.name_id = "bm_wp_model70_b_legend"
	self.parts.wpn_fps_snp_model70_s_legend.name_id = "bm_wp_model70_s_legend"

	--Fix foregrip on Raven Admiral
	--Without this, the foregrip will disappear if you apply the Short Barrel then switch to the Admiral Barrel
	safe_add_value("wpn_fps_sho_ksg_b_legendary", "forbids", "wpn_fps_sho_ksg_fg_short")
	safe_add_value("wpn_fps_sho_ksg_b_legendary", "adds", "wpn_fps_sho_ksg_fg_standard")

	--Big Kahuna
	--Legendary stock forbids default grip
	safe_add_value("wpn_fps_shot_r870_s_legendary", "forbids", "wpn_fps_upg_m4_g_standard")

	--Demon
	--Legendary stock forbids default grip
	safe_add_value("wpn_fps_shot_shorty_s_legendary", "forbids", "wpn_fps_upg_m4_g_standard")

	--Mars Ultor
	--Legendary barrel forbids default barrel extension
	safe_add_value("wpn_fps_ass_tecci_b_legend", "forbids", "wpn_fps_ass_tecci_ns_standard")

	--Astatoz
	--Legendary foregrip type changed to "foregrip" (instead of "gadget")
	self.parts.wpn_fps_ass_m16_fg_legend.type = "foregrip"

	--Vlad's Rodina
	--Legendary stock adds default grip
	--Legendary grip forbids default grip
	safe_add_value("wpn_upg_ak_s_legend", "adds", "wpn_upg_ak_g_standard")
	safe_add_value("wpn_upg_ak_g_legend", "forbids", "wpn_upg_ak_g_standard")
end)
