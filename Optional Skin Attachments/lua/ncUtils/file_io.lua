ncUtils.FileIO = {}

--Replace backslashes with forward slashes
--Remove duplicate slashes
--Remove trailing slashes
function ncUtils.FileIO:normalize(path)
	path = path:gsub("\\", "/")
	path = path:gsub("/+", "/")
	path = path:gsub("/+$", "")
	return path
end

--Note: trailing slashes are removed.
function ncUtils.FileIO:file_exists(path)
	return file.FileExists(self:normalize(path))
end

function ncUtils.FileIO:folder_exists(path)
	return file.DirectoryExists(self:normalize(path))
end

function ncUtils.FileIO:path_exists(path)
	path = self:normalize(path)
	return self:file_exists(path) or self:folder_exists(path)
end

--Requires a normalized path.
function ncUtils.FileIO:_get_parent_directory(path)
	return path:match("^(.*)/[^/]+$")
end

--Create all missing parent directories of a path.
--Requires a normalized path.
function ncUtils.FileIO:_create_parent_directory(path)
	local parent = self:_get_parent_directory(path)
	if not parent then
		return true
	end

	return self:create_folder(parent)
end

--Create a directory and all missing parent directories recursively.
function ncUtils.FileIO:create_folder(path)
	path = self:normalize(path)

	if self:folder_exists(path) then
		return true
	end

	if not self:_create_parent_directory(path) then
		return false
	end

	return file.CreateDirectory(path)
end

--Create a file and all parents recursively
function ncUtils.FileIO:create_file(path)
	path = self:normalize(path)

	if self:path_exists(path) then
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
	if not ikwid then
		return false
	end

	path = self:normalize(path)

	if not self:file_exists(path) then
		return false
	end

	return os.remove(path) ~= nil
end

--Recursively delete path because RemoveDirectory only works on empty folders
function ncUtils.FileIO:delete_folder(path, ikwid)
	if not ikwid then
		return false
	end

	path = self:normalize(path)

	if not self:folder_exists(path) then
		return false
	end

	return self:_delete_folder(path)
end

--Recursively delete path because RemoveDirectory only works on empty folders
--Make sure to normalize path and check folder exists before calling.
function ncUtils.FileIO:_delete_folder(path)
	--1. Recursion to clean any subfolders
	local result = true
	local dirs = file.GetDirectories(path) or {}
	for _, dir in pairs(dirs) do
		result = self:_delete_folder(path .. "/" .. dir) and result
	end

	--2. Remove files from path
	local files = file.GetFiles(path) or {}
	for _, file in pairs(files) do
		local file_path = path .. "/" .. file
		result = (os.remove(file_path) ~= nil) and result
	end

	--3. Remove path
	return file.RemoveDirectory(path) and result
end

function ncUtils.FileIO:move_folder(old_path, new_path)
	old_path = self:normalize(old_path)
	new_path = self:normalize(new_path)

	if not self:folder_exists(old_path) then
		return false
	end
	if self:path_exists(new_path) then
		return false
	end

	if not self:_create_parent_directory(new_path) then
		return false
	end

	return file.MoveDirectory(old_path, new_path)
end

function ncUtils.FileIO:copy_file(old_path, new_path)
	old_path = self:normalize(old_path)
	new_path = self:normalize(new_path)

	if not self:file_exists(old_path) then
		return false
	end
	if self:path_exists(new_path) then
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

--Partial failure possible: copy can succeed while deleting the old file fails.
--Copy and delete have to normalize so we can skip it here.
function ncUtils.FileIO:move_file(old_path, new_path)
	if not self:copy_file(old_path, new_path) then
		return false
	end

	return self:delete_file(old_path, true)
end

function ncUtils.FileIO:save_json(path, data, overwrite)
	path = self:normalize(path)

	if self:folder_exists(path) then
		return false
	end

	if not overwrite and self:file_exists(path) then
		return false
	end

	if not self:_create_parent_directory(path) then
		return false
	end

	local file = io.open(path, "w")
	if not file then
		return false
	end

	file:write(json.encode(data))
	file:close()

	return true
end

function ncUtils.FileIO:load_json(path)
	path = self:normalize(path)

	local file = io.open(path, "r")
	if not file then
		return nil
	end

	local data = json.decode(file:read("*all"))
	file:close()

	return data
end
