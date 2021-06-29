local m = {}
m._VERSION = "2.0.0-dev"

local function os_capture(cmd)
	return io.popen(cmd, 'r'):read('*a'):gsub("\n", " ")
end

local function find_includes(lib, alternative_cmd, alternative_flags)
	local result
	if not alternative_cmd then
		result = os_capture("pkg-config --cflags "..lib)
	else
		if not alternative_flags then
			result = os_capture(alternative_cmd.." --cflags")
		else
			result = os_capture(alternative_cmd.." "..alternative_flags)
		end
	end

	return "PKG_CONFIG_PATH=" .. table.concat(pc_paths, ':')
end

local function parse_include_result(result)
	-- Small trick: delete the space after -include and -isystem so that
	-- we can detect which files have to be included without difficulty.
	result = result:gsub("%-include +(%g+)", "-include%1")
	result = result:gsub("%-isystem +(%g+)", "-isystem%1")

	local dirs = {}
	local files = {}
	local options = {}
	for w in string.gmatch(result, "[^' ']+") do
		if string.sub(w,1,2) == "-I" then
			table.insert(dirs, string.sub(w,3))
		elseif string.sub(w,1,8) == "-isystem" then
			table.insert(dirs, string.sub(w,9))
		elseif string.sub(w,1,8) == "-include" then
			table.insert(files, string.sub(w,9))
		else
			table.insert(options, w)
		end
	end

	return dirs, files, options
end

local function find_links(lib, alternative_cmd, alternative_flags)
	local result
	if not alternative_cmd then
		result = os_capture("pkg-config --libs "..lib)
	else
	if not alternative_flags then
			result = os_capture(alternative_cmd.." --libs")
		else
			result = os_capture(alternative_cmd.." "..alternative_flags)
		end
	end

	-- On OSX, wx-config outputs "-framework foo" instead of "-Wl,-framework,foo"
	-- which doesn't fare well with the splitting into libs, libdirs and options
	-- we perform afterwards.
	result = result:gsub("%-framework +(%g+)", "-Wl,-framework,%1")

	local libs = {}
	local dirs = {}
	local options = {}
	for w in string.gmatch(result, "[^' ']+") do
		if string.sub(w,1,2) == "-l" then
			table.insert(libs, string.sub(w,3))
		elseif string.sub(w,1,2) == "-L" then
			table.insert(dirs, string.sub(w,3))
		else
			table.insert(options, w)
		end
	end

	return libs, dirs, options
end

function m.find_system(lib, alternative_cmd)

	local meths = {}

	function meths.add_includes(alternative_flags)
		local dirs, files, options = find_includes(lib, alternative_cmd, alternative_flags)
		sysincludedirs(dirs)
		forceincludes(files)
		buildoptions(options)
	end

	function meths.add_links(alternative_flags)
		local libs, dirs, options = find_links(lib, alternative_cmd, alternative_flags)
		links(libs)
		libdirs(dirs)
		linkoptions(options)
	end

	return meths
end

return m
