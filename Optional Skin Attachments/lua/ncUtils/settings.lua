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

	local data = ncUtils.FileIO:load_json(save_file)
	data = type(data) == "table" and data or nil

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

--Called internally by load which already checked that Mod.meta exists.
--Only do a few minimal safety checks.
function ncUtils.Settings:_migrate(data, Mod)
	--Check data is valid.
	data = type(data) == "table" and data or nil
	--Name of the save file that was loaded. nil if no valid data was loaded.
	local loaded_save = data and Mod.meta.save_file
	if not Mod.save_migration then
		return data, false
	end

	local migrated = false
	for _, migration in ipairs(Mod.save_migration) do
		--If no data, load the legacy save file if the mod declared one.
		--Otherwise, we only check if there are settings keys to migrate.
		if not data and migration.file then
			local new_data = ncUtils.FileIO:load_json(migration.file)
			if type(new_data) == "table" then
				data = new_data
				loaded_save = migration.file
				migrated = true
			end
		end

		--If we loaded a valid legacy save, we always have a save match.
		--If the initial load was valid, we also have a match if migration.file was not declared.
		local save_match = loaded_save == migration.file or not migration.file
		--We can migrate if we have valid data, a save match, and the migration declares a key map.
		local can_migrate = data and save_match and migration.key_map
		if can_migrate then
			for old_key, new_key in pairs(migration.key_map) do
				local new_key_value = data[new_key]
				local old_key_value = data[old_key]
				if new_key_value == nil and old_key_value ~= nil then
					if type(old_key_value) == type(Mod.settings[new_key]) then
						data[new_key] = old_key_value
						data[old_key] = nil
						migrated = true
					end
				end
			end
		end
		--Stop as soon as we migrated.
		if migrated then
			break
		end
	end

	return data, migrated
end
