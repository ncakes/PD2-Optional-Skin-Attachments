_G[ModPath] = _G[ModPath] or {}
if _G[ModPath][RequiredScript] then return end
_G[ModPath][RequiredScript] = true

Hooks:PostHook(MenuManager, "init", "OSA-PostHook-MenuManager:init", function(...)
	--Prevent disabling legendary support if using SDSS
	if _G.SDSS then
		ncUtils.Menu:disable_item("gen1_legend_support", OSA)
	end

	--Legendary swapping requires AOLA
	if not _G.AOLA then
		ncUtils.Menu:set_item_value("autoswap_legend", false, OSA)
		ncUtils.Menu:disable_item("autoswap_legend", OSA)
	end
end)
