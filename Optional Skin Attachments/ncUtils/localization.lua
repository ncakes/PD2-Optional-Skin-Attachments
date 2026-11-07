ncUtils.Localization = {}

function ncUtils.Localization:load(loc, Mod)
	local loc_path = Mod and Mod.meta and Mod.meta.loc_path
	if not loc_path then
		return
	end

	--Process automatic localizations first
	local auto_loc = ncUtils.FileIO:load_json(loc_path .. "auto.json") or {}
	for k, v in pairs(auto_loc) do
		auto_loc[k] = loc:text(v)
	end
	loc:add_localized_strings(auto_loc)

	--Load default language
	local default_lang = Mod.meta.language or "en"
	loc:load_localization_file(loc_path .. default_lang .. ".json")

	--Load BLT language
	if Mod.meta.localized then
		local data, _ = BLT.Localization:get_language()
		local lang_code = data and data.language or default_lang
		if lang_code:lower() ~= default_lang:lower() then
			loc:load_localization_file(loc_path .. lang_code .. ".json")
		end
	end
end
