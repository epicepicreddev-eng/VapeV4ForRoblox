```lua
local isfile = isfile or function(file)
	local suc, res = pcall(function()
		return readfile(file)
	end)

	return suc and type(res) == "string"
end

local delfile = delfile or function(file)
	if isfile(file) then
		writefile(file, "--deleted")
	end
end

local function safeRead(path, default)
	if not isfile(path) then
		return default
	end

	local suc, res = pcall(readfile, path)
	return suc and res or default
end

local function ensureFolder(path)
	if not isfolder(path) then
		makefolder(path)
	end
end

local function wipeFolder(path)
	if not isfolder(path) then
		return
	end

	for _, file in listfiles(path) do
		if file:find("loader") then
			continue
		end

		if isfile(file) then
			local suc, content = pcall(readfile, file)

			if suc and type(content) == "string" then
				if content:find("^%-%-This watermark is used to delete the file if its cached") then
					delfile(file)
				end
			end
		end
	end
end

for _, folder in {
	"newvape",
	"newvape/games",
	"newvape/profiles",
	"newvape/assets",
	"newvape/libraries",
	"newvape/guis"
} do
	ensureFolder(folder)
end

local commitFile = "newvape/profiles/commit.txt"

if not shared.VapeDeveloper then
	local suc, githubPage = pcall(function()
		return game:HttpGet(
			"https://github.com/7GrandDadPGN/VapeV4ForRoblox",
			true
		)
	end)

	local commit = "main"

	if suc and type(githubPage) == "string" then
		local pos = githubPage:find("currentOid")

		if pos then
			local extracted = githubPage:sub(pos + 13, pos + 52)

			if #extracted == 40 then
				commit = extracted
			end
		end
	end

	local oldCommit = safeRead(commitFile, "")

	if oldCommit ~= commit then
		wipeFolder("newvape")
		wipeFolder("newvape/games")
		wipeFolder("newvape/guis")
		wipeFolder("newvape/libraries")
	end

	writefile(commitFile, commit)
end

local function downloadFile(path, func)
	if not isfile(path) then
		local commit = safeRead(commitFile, "main")

		local relativePath = select(1, path:gsub("^newvape/", ""))

		local url =
			"https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/"
			.. commit
			.. "/"
			.. relativePath

		local suc, res = pcall(function()
			return game:HttpGet(url, true)
		end)

		if not suc then
			error("Failed to download: " .. tostring(res))
		end

		if type(res) ~= "string" or res == "" or res == "404: Not Found" then
			error("Invalid response while downloading: " .. relativePath)
		end

		if type(res) == "string" then
			res = res
				:gsub("Vape V4", "Vanguard V4")
				:gsub("Vape", "Vanguard")
		end

		if path:find("%.lua$") then
			res =
				"--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n"
				.. res
		end

		writefile(path, res)
	end

	local reader = func or readfile

	local suc, res = pcall(reader, path)

	if not suc then
		error("Failed to read file: " .. path)
	end

	return res
end

local mainSource = downloadFile("newvape/main.lua")

mainSource = mainSource
	:gsub("Vape V4", "Vanguard V4")
	:gsub("Vape", "Vanguard")

local compiled, err = loadstring(mainSource, "main")