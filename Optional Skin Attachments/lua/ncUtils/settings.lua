ncUtils.Settings = {}

function ncUtils.Settings:exists(Mod)
	local save_file = Mod and Mod.meta and Mod.meta.save_file
	if not save_file then
		return
	end
	return ncUtils.FileIO:file_exists(save_file)
end

function ncUtils.Settings:save(Mod)
	local save_file = Mod and Mod.meta and Mod.meta.save_file
	local settings = Mod and Mod.settings
	if not save_file or not settings then
		return
	end

	return ncUtils.FileIO:save_json(save_file, settings, true)
end

--Mod.settings table should contain keys and default values.
--Keys that are in the save file but are not in Mod.settings will not be loaded.
--Basic validation only: checks the loaded type is the same as the default setting.
function ncUtils.Settings:load(Mod)
	local save_file = Mod and Mod.meta and Mod.meta.save_file
	local settings = Mod and Mod.settings
	if not save_file or not settings then
		return
	end

	--load_json guarantees a table or nil
	local data = ncUtils.FileIO:load_json(save_file)

	local migrated = false
	if Mod.save_migration then
		data, migrated = self:_migrate(data, Mod)
	end

	if type(data) ~= "table" then
		return
	end

	--Missing values fail the type check and keep their defaults.
	for k, default_value in pairs(settings) do
		local value = data[k]
		if type(value) == type(default_value) then
			settings[k] = value
		end
	end

	if migrated then
		ncUtils.FileIO:save_json(save_file, settings, true)
	end
end

--No safety checks. Caller checks that Mod has the necessary definitions.
function ncUtils.Settings:_migrate(data, Mod)
	--Name of the save file that was loaded. nil if no valid data was loaded.
	local loaded_save = data and Mod.meta.save_file

	--Migration entries are ordered newest to oldest and processed in order.
	--Processing stops after the first successfully loaded save.
	--If we already have a loaded_save, only the first migration entry is processed.
	--Only the first entry may omit file to migrate keys in the current save.
	--Later entries must specify file; otherwise they cannot load any data.
	local migrated = false
	for _, migration in ipairs(Mod.save_migration) do
		--If no data, try to load the legacy save file.
		if not data and migration.file then
			data = ncUtils.FileIO:load_json(migration.file)
			if data then
				loaded_save = migration.file
				migrated = true
			end
		end

		if data then
			--Migrate keys only when the entry matches the loaded save.
			--For current-save migration, file can be omitted.
			local save_match = loaded_save == migration.file or not migration.file
			local can_migrate_keys = save_match and migration.key_map
			if can_migrate_keys then
				--key_map_only is only supported for legacy saves.
				--Ignore it for current saves to avoid discarding existing settings.
				local key_map_only = migration.key_map_only
				if key_map_only and loaded_save == Mod.meta.save_file then
					log("[ncUtils] Settings:_migrate() key_map_only not allowed for current save: " .. Mod.meta.save_file)
					key_map_only = false
				end

				local result = {}
				--Preserve existing data unless only mapped keys should be kept.
				if not key_map_only then
					for k, v in pairs(data) do
						result[k] = v
					end
				end

				for old_key, new_key in pairs(migration.key_map) do
					local new_value = data[new_key]
					local old_value = data[old_key]
					if new_value == nil and old_value ~= nil then
						new_value = old_value
						migrated = true
					end
					result[new_key] = new_value
				end

				data = result
			end

			--Stop as soon as a save is loaded.
			break
		end
	end

	return data, migrated
end
