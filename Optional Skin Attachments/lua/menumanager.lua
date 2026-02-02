Hooks:PostHook(MenuManager, "init", "OSA-PostHook-MenuManager:init", function(...)
	OSA:update_menu_options()

	--Prevent disabling legendary support if using SDSS
	if _G.SDSS then
		local item = OSA:get_menu_item("osa_gen1_support")
		item._enabled = false
	end

	--Legendary swapping not yet implemented, disable option
	if not _G.AOLA or true then
		local item = OSA:get_menu_item("osa_swap_legend")
		item._current_index = 3
		item._enabled = false
	end
end)
