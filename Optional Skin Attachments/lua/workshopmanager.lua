Hooks:PostHook(WorkshopManager, "init", "OSA-PostHook-WorkshopManager:init", function(...)
	if OSA.settings.remove_beardlib_blueprints then
		OSA:remove_custom_weapon_blueprints()
	end
end)
