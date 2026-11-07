ncUtils.Bootstrap = {}

function ncUtils.Bootstrap:blt_mod(mod_folder, manifest_path, callback)
	local function run_callback(status)
		if callback then
			callback(status)
		end
	end

	if not BLTMod or not BLT.Downloads or not BLT.Downloads.add_pending_download then
		run_callback("failed")
		return
	end

	mod_folder = ncUtils.FileIO:normalize(mod_folder)
	if mod_folder:find("/", 1, true) then
		run_callback("failed")
		return
	end
	if mod_folder == "" or mod_folder == "." or mod_folder == ".." then
		run_callback("failed")
		return
	end

	--Start bootstrapping.
	local mod_path = "mods/" .. mod_folder .. "/"
	if ncUtils.FileIO:path_exists(mod_path) then
		run_callback("failed")
		return
	end

	if not ncUtils.FileIO:copy_file(manifest_path, mod_path .. "mod.txt") then
		run_callback("failed")
		return
	end

	local new_mod, valid = BLTMod:new(mod_folder, nil, mod_path)
	if not valid or not new_mod or not new_mod:HasUpdates() then
		run_callback("failed")
		return
	end

	--From BLTViewModGui:clbk_check_for_updates_finished
	new_mod:CheckForUpdates(function(cache)
		local queued = false
		for update_id, data in pairs(cache or {}) do
			if data.requires_update then
				BLT.Downloads:add_pending_download(data.update)
				queued = true
			end
		end
		run_callback(queued and "queued" or "failed")
	end)
end
