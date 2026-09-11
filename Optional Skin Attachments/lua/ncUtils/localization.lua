ncUtils.Localization = {}

--Load localization strings from <loc_path>/<lang_code>.json.
--Uses BLT language code. Falls back to Mod.language or "en" for any missing entries.
--Process <loc_path>/auto.json which maps custom string_ids to base game string_ids.
--Priority is BLT language -> fallback language -> auto.json.
--Load in reverse order and overwrite.
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

	--Load fallback language
	local fallback_lang = Mod.language or "en"
	loc:load_localization_file(loc_path .. fallback_lang .. ".json")

	--Load BLT language
	local data, _ = BLT.Localization:get_language()
	local lang_code = data and data.language or fallback_lang
	if lang_code:lower() ~= fallback_lang:lower() then
		loc:load_localization_file(loc_path .. lang_code .. ".json")
	end
end
