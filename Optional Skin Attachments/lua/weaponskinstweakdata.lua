_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

--Warning: removing default_blueprint can trigger false-positives in the anti-piracy code if not done properly.
--Should also check special_blueprint after U242.
Hooks:PostHook(BlackMarketTweakData, "_init_weapon_skins", "OSA-PostHook-BlackMarketTweakData:_init_weapon_skins", function(self, tweak_data)
	--Force legendary support if SDSS detected
	--This is early enough that legendary features will be properly enabled
	if _G.SDSS and not OSA.settings.gen1_legend_support then
		OSA.settings.gen1_legend_support = true
		ncUtils.Settings:save(OSA)
	end

	--Remove empty blueprints from skins without attachments
	--Almost everything has been fixed in the base game, just hardcode these
	local no_attachments = {"b682_skf", "r93_css", "c96_dss", "plainsrider_skullimov"}
	for _, skin_id in pairs(no_attachments) do
		self.weapon_skins[skin_id].default_blueprint = nil
	end

	--Remove unique name so that legendary skins can be renamed
	--Unlock first-generation legendary skins
	for _, skin in pairs(self.weapon_skins) do
		skin.unique_name_id = nil
		if OSA.settings.gen1_legend_support then
			skin.locked = nil
		end
	end

	local function safe_add_blueprint(skin_id, part_id)
		local blueprint = self.weapon_skins[skin_id].default_blueprint
		if not blueprint then
			log("[OSA] No blueprint for skin_id " .. skin_id)
			return
		end
		if not table.contains(blueprint, part_id) then
			table.insert(blueprint, part_id)
		end
	end

	--The Judge Anarcho blueprint omits the default Judge barrel (type "slide").
	--The legendary barrel is type "barrel", so it does not replace the default slide.
	--Barrel extensions expect a slide parent and can crash when none exists.
	--Keep the default barrel in the blueprint to ensure multiplayer compatibility.
	safe_add_blueprint("judge_burn", "wpn_fps_pis_judge_b_standard")

	--The Alamo Dallas blueprint omits the default barrel (type "barrel").
	--The legendary barrel is type "slide", so it does not replace the default barrel.
	--Barrel extensions expect a barrel parent and can crash when none exists.
	--Keep the default barrel in the blueprint to ensure multiplayer compatibility.
	safe_add_blueprint("p90_dallas_sallad", "wpn_fps_smg_p90_b_short")

	--Big Kahuna. Add default grip.
	safe_add_blueprint("r870_waves", "wpn_fps_upg_m4_g_standard")

	--Demon. Add default grip.
	safe_add_blueprint("serbu_lones", "wpn_fps_upg_m4_g_standard")

	--Mars Ultor. Add default barrel extension.
	safe_add_blueprint("tecci_grunt", "wpn_fps_ass_tecci_ns_standard")
end)
