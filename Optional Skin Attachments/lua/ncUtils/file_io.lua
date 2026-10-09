ncUtils.FileIO = {}

--Normalize path syntax without resolving path components.
function ncUtils.FileIO:normalize(path)
	path = path:gsub("\\", "/")
	path = path:gsub("/+", "/")
	path = path:gsub("/+$", "")
	return path
end

--Check whether a normalized path is valid for ncUtils.
function ncUtils.FileIO:_is_valid(path)
	--SuperBLT handles empty, root, and rooted paths inconsistently.
	--Some file functions may even cause fatal C++ exceptions.
	if path == "" or path == "/" or path:match("^/") then
		return false
	end

	return true
end

--Restrict file system modifications to safe relative paths.
--Reject absolute Windows paths and any form of parent traversal.
function ncUtils.FileIO:_can_mutate(path)
	--Mutation safety restrictions are bypassed in devmode.
	if ncUtils.devmode then
		return true
	end

	--Prevent mutation of the PAYDAY 2 folder itself.
	if path == "." then
		return false
	end

	--Reject colons to prevent Windows drive paths.
	if path:find(":", 1, true) then
		return false
	end

	--Reject parent traversal and paths containing only current-directory components.
	local has_target = false
	for part in path:gmatch("[^/]+") do
		if part == ".." then
			return false
		elseif part ~= "." then
			has_target = true
		end
	end
	if not has_target then
		return false
	end

	return true
end

function ncUtils.FileIO:file_exists(path)
	path = self:normalize(path)
	if not self:_is_valid(path) then
		return nil
	end

	return file.FileExists(path)
end

function ncUtils.FileIO:folder_exists(path)
	path = self:normalize(path)
	if not self:_is_valid(path) then
		return nil
	end

	return file.DirectoryExists(path)
end

function ncUtils.FileIO:path_exists(path)
	path = self:normalize(path)
	if not self:_is_valid(path) then
		return nil
	end

	return file.FileExists(path) or file.DirectoryExists(path)
end

--Validate that path is an existing directory before calling GetFiles.
--SuperBLT may cause a fatal C++ exception otherwise.
function ncUtils.FileIO:get_files(path)
	path = self:normalize(path)
	if not self:_is_valid(path) then
		return nil
	end

	if not file.DirectoryExists(path) then
		return nil
	end

	return file.GetFiles(path)
end

--Validate that path is an existing directory before calling GetDirectories.
--SuperBLT may cause a fatal C++ exception otherwise.
function ncUtils.FileIO:get_folders(path)
	path = self:normalize(path)
	if not self:_is_valid(path) then
		return nil
	end

	if not file.DirectoryExists(path) then
		return nil
	end

	return file.GetDirectories(path)
end

function ncUtils.FileIO:_get_parent_directory(path)
	return path:match("^(.*)/[^/]+$")
end

--Create all missing parent directories of a path.
function ncUtils.FileIO:_create_parent_directory(path)
	local parent = self:_get_parent_directory(path)
	if not parent or parent == "." or file.DirectoryExists(parent) then
		return true
	end

	return self:create_folder(parent)
end

--Create a folder and all missing parent directories recursively.
function ncUtils.FileIO:create_folder(path)
	path = self:normalize(path)
	if not self:_is_valid(path) then
		return false
	end

	if not self:_can_mutate(path) then
		log("[ncUtils] FileIO:create_folder() mutation path not permitted: " .. path)
		return false
	end

	if file.FileExists(path) or file.DirectoryExists(path) then
		return false
	end

	if not self:_create_parent_directory(path) then
		return false
	end

	return file.CreateDirectory(path)
end

--Create a file and all missing parent directories recursively.
function ncUtils.FileIO:create_file(path)
	path = self:normalize(path)
	if not self:_is_valid(path) then
		return false
	end

	if not self:_can_mutate(path) then
		log("[ncUtils] FileIO:create_file() mutation path not permitted: " .. path)
		return false
	end

	if file.FileExists(path) or file.DirectoryExists(path) then
		return false
	end

	if not self:_create_parent_directory(path) then
		return false
	end

	local file = io.open(path, "w")
	if file then
		file:close()
		return true
	end

	return false
end

function ncUtils.FileIO:delete_file(path, ikwid)
	if ikwid ~= true then
		return false
	end

	path = self:normalize(path)
	if not self:_is_valid(path) then
		return false
	end

	if not self:_can_mutate(path) then
		log("[ncUtils] FileIO:delete_file() mutation path not permitted: " .. path)
		return false
	end

	if not file.FileExists(path) then
		return false
	end

	return os.remove(path) ~= nil
end

--Recursively delete path because RemoveDirectory only works on empty folders
function ncUtils.FileIO:delete_folder(path, ikwid)
	if ikwid ~= true then
		return false
	end

	path = self:normalize(path)
	if not self:_is_valid(path) then
		return false
	end

	if not self:_can_mutate(path) then
		log("[ncUtils] FileIO:delete_folder() mutation path not permitted: " .. path)
		return false
	end

	if not file.DirectoryExists(path) then
		return false
	end

	return self:_delete_folder(path)
end

--Recursively delete path because RemoveDirectory only works on empty folders
--Requires a normalized, valid, existing folder path.
function ncUtils.FileIO:_delete_folder(path)
	local result = true

	--1. Remove files from path
	local files = file.GetFiles(path)
	for _, file in ipairs(files) do
		local file_path = path .. "/" .. file
		result = (os.remove(file_path) ~= nil) and result
	end

	--2. Recursion to clean any subfolders
	local dirs = file.GetDirectories(path)
	for _, dir in ipairs(dirs) do
		result = self:_delete_folder(path .. "/" .. dir) and result
	end

	--3. Remove path
	return file.RemoveDirectory(path) and result
end

--Warning: folder copying is intentionally not provided.
--A recursive folder copy must guarantee that new_path is not a subdirectory of old_path.
--Otherwise the recursion will continue indefinitely.
--Path resolution must consider parent traversal, absolute paths, and other edge cases.
function ncUtils.FileIO:copy_file(old_path, new_path)
	old_path = self:normalize(old_path)
	new_path = self:normalize(new_path)

	if not self:_is_valid(old_path) or not self:_is_valid(new_path) then
		return false
	end

	if not self:_can_mutate(new_path) then
		log("[ncUtils] FileIO:copy_file() mutation path not permitted: " .. new_path)
		return false
	end

	if not file.FileExists(old_path) then
		return false
	end

	if file.FileExists(new_path) or file.DirectoryExists(new_path) then
		return false
	end

	if not self:_create_parent_directory(new_path) then
		return false
	end

	local source_file = io.open(old_path, "rb")
	if not source_file then
		return false
	end
	local source_data = source_file:read("*all")
	source_file:close()
	if source_data == nil then
		return false
	end

	local destination_file = io.open(new_path, "wb")
	if not destination_file then
		return false
	end
	local success = destination_file:write(source_data)
	destination_file:close()

	if not success then
		os.remove(new_path)
		return false
	end

	return true
end

function ncUtils.FileIO:move_file(old_path, new_path)
	old_path = self:normalize(old_path)
	new_path = self:normalize(new_path)

	if not self:_is_valid(old_path) or not self:_is_valid(new_path) then
		return false
	end

	if not self:_can_mutate(old_path) then
		log("[ncUtils] FileIO:move_file() mutation path not permitted: " .. old_path)
		return false
	end

	if not self:_can_mutate(new_path) then
		log("[ncUtils] FileIO:move_file() mutation path not permitted: " .. new_path)
		return false
	end

	if not file.FileExists(old_path) then
		return false
	end

	if file.FileExists(new_path) or file.DirectoryExists(new_path) then
		return false
	end

	if not self:_create_parent_directory(new_path) then
		return false
	end

	return os.rename(old_path, new_path) ~= nil
end

function ncUtils.FileIO:move_folder(old_path, new_path)
	old_path = self:normalize(old_path)
	new_path = self:normalize(new_path)

	if not self:_is_valid(old_path) or not self:_is_valid(new_path) then
		return false
	end

	if not self:_can_mutate(old_path) then
		log("[ncUtils] FileIO:move_folder() mutation path not permitted: " .. old_path)
		return false
	end

	if not self:_can_mutate(new_path) then
		log("[ncUtils] FileIO:move_folder() mutation path not permitted: " .. new_path)
		return false
	end

	if not file.DirectoryExists(old_path) then
		return false
	end

	if file.FileExists(new_path) or file.DirectoryExists(new_path) then
		return false
	end

	if not self:_create_parent_directory(new_path) then
		return false
	end

	return file.MoveDirectory(old_path, new_path)
end

--Opening an existing file with "w" truncates it before writing.
--If the subsequent write fails, the original contents are already lost.
--A new file may likewise remain empty or partially written after failure.
function ncUtils.FileIO:save_json(path, data, overwrite)
	path = self:normalize(path)
	if not self:_is_valid(path) then
		return false
	end

	if not self:_can_mutate(path) then
		log("[ncUtils] FileIO:save_json() mutation path not permitted: " .. path)
		return false
	end

	if type(data) ~= "table" then
		log("[ncUtils] FileIO:save_json() expected table, got " .. type(data) .. ": " .. path)
		return false
	end

	if file.DirectoryExists(path) then
		return false
	end

	if overwrite ~= true and file.FileExists(path) then
		return false
	end

	local encode_ok, encoded_data = pcall(json.encode, data)
	if not encode_ok or not encoded_data then
		return false
	end

	if not self:_create_parent_directory(path) then
		return false
	end

	local file = io.open(path, "w")
	if not file then
		return false
	end

	local success = file:write(encoded_data)
	file:close()

	return success ~= nil
end

function ncUtils.FileIO:load_json(path)
	path = self:normalize(path)
	if not self:_is_valid(path) then
		return nil
	end

	local file = io.open(path, "r")
	if not file then
		return nil
	end

	local contents = file:read("*all")
	file:close()

	if contents == nil then
		return nil
	end

	local data = json.decode(contents)

	if data ~= nil and type(data) ~= "table" then
		log("[ncUtils] FileIO:load_json() expected decoded table, got " .. type(data) .. ": " .. path)
		return nil
	end

	return data
end
