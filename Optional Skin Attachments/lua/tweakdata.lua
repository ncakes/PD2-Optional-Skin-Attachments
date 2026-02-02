if not OSA.settings.osa_remove_beardlib_blueprints then
	return
end

--Completely remove blueprints from custom weapons
local weapon_skins = tweak_data and tweak_data.blackmarket and tweak_data.blackmarket.weapon_skins
for k, v in pairs(weapon_skins or {}) do
	if v.custom and v.default_blueprint then
		v.default_blueprint = nil
	end
end
