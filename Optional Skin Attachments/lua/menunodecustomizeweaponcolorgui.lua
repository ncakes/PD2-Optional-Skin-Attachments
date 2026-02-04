Hooks:PreHook(MenuCustomizeWeaponColorInitiator, "setup_node", "OSA-PreHook-MenuCustomizeWeaponColorInitiator:setup_node", function(self, node, node_data)
	if OSA.settings.osa_pattern_scale > 1 then
		node_data.pattern_scale = OSA.settings.osa_pattern_scale - 1
	end
end)
