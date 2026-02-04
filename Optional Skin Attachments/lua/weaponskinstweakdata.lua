--Warning: removing default_blueprint can trigger false-positives in the anti-piracy code if not done properly.
--Should also check special_blueprint after U242.
Hooks:PostHook(BlackMarketTweakData, "_init_weapon_skins", "OSA-PostHook-BlackMarketTweakData:_init_weapon_skins", function(self, tweak_data)
	--Force legendary support if SDSS detected
	--This is early enough that legendary features will be properly enabled
	if _G.SDSS and not OSA.settings.osa_gen1_support then
		OSA.settings.osa_gen1_support = true
		OSA:save_settings()
	end

	--Remove empty blueprints from skins without attachments
	--Almost everything has been fixed in the base game, just hardcode these
	local no_attachments = {"b682_skf", "r93_css", "c96_dss", "plainsrider_skullimov"}
	for _, skin_id in pairs(no_attachments) do
		self.weapon_skins[skin_id].default_blueprint = nil
	end

	--Remove unique name so that legendary skins can be renamed
	for _, skin in pairs(self.weapon_skins) do
		if not skin.locked then
			--Rename gen2 legendary
			skin.unique_name_id = nil
		elseif OSA.settings.osa_gen1_support then
			--Unlock gen1
			skin.unique_name_id = nil
			skin.locked = nil
		end

		--Set "MODIFICATIONS INCLUDED" description for skins which have blueprints
		if skin.rarity ~= "legendary" then
			skin.desc_id = skin.default_blueprint and "osa_bm_has_attachments" or nil
		end
	end

	--If we deep clone a Judge Anarcho blueprint and try to put a barrel extension on it, the game crashes
	--But if we start with a default Judge, put all the Anarcho attachments on it, and then equip a barrel extension, it doesn't crash
	--Apparently it's because the Anarcho doesn't have the the default Judge barrel in its blueprint
	--I guess for some reason the Anarcho barrel doesn't replace the default barrel?
	--Either way, this fixes the crash
	if not table.contains(self.weapon_skins["judge_burn"].default_blueprint, "wpn_fps_pis_judge_b_standard") then
		table.insert(self.weapon_skins["judge_burn"].default_blueprint, "wpn_fps_pis_judge_b_standard")
	end
end)
