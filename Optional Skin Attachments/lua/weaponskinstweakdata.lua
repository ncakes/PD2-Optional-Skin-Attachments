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
	--Unlock first generation legendary skins
	for _, skin in pairs(self.weapon_skins) do
		skin.unique_name_id = nil
		if OSA.settings.gen1_legend_support then
			skin.locked = nil
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
