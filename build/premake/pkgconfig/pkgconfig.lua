local m = {}
m._VERSION = "2.0.0-dev"

m.additional_pc_path_release = nil
m.additional_pc_path_debug   = nil
m.binary = "pkg-config"
m.static_link_libs = false

local function os_capture(cmd)
	return io.popen(cmd, 'r'):read('*a'):gsub("\n", " ")
end

function m.get_pc_path(configuration_option)
	-- Assemble PKG_CONFIG_PATH
	--
	-- In the case that a dependency doesn't differentiate between release/debug, we expect
	-- whatever *.pc file that is provided to be in the Release location.
	--
	-- We don't assume that there is always a directory for "Release" configs, as it is possible
	-- that Release uses *.pc files found globally on a system whilst "Debug" uses a custom
	-- directory.

	local pc_paths = {}

	if string.lower(configuration_option) == "debug" and m.additional_pc_path_debug then
		table.insert(pc_paths, m.additional_pc_path_debug)
	end

	if m.additional_pc_path_release then
		table.insert(pc_paths, m.additional_pc_path_release)
	end

	if #pc_paths == 0 then
		return ""
	end

	if os.istarget("windows") then
		-- Hint: it's a cmd.exe shell
		return "set PKG_CONFIG_PATH=" .. table.concat(pc_paths, ';') .. "; & "
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

local function parse_link_result(result)
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
		if alternative_cmd then
			local flags = alternative_flags or " --cflags"
			local result = os_capture(alternative_cmd .. " " .. flags)
			local dirs, files, options = parse_include_result(result)
			sysincludedirs(dirs)
			forceincludes(files)
			buildoptions(options)
		
		else
			filter "Debug"
				local pc_path = m.get_pc_path("debug")
				local result = os_capture(pc_path .. " " .. m.binary .. " --cflags " .. lib)
				local dirs, files, options = parse_include_result(result)
				sysincludedirs(dirs)
				forceincludes(files)
				buildoptions(options)

			filter "Release"
				local pc_path = m.get_pc_path("release")
				local result = os_capture(pc_path .. " " .. m.binary .. " --cflags " .. lib)
				local dirs, files, options = parse_include_result(result)
				sysincludedirs(dirs)
				forceincludes(files)
				buildoptions(options)

			filter { }
		end
	end

	function meths.add_links(alternative_flags)
		if alternative_cmd then
			local flags = alternative_flags or " --libs"
			local result = os_capture(alternative_cmd .. " " .. flags)
			local libs, dirs, options = parse_link_result(result)
			links(libs)
			libdirs(dirs)
			linkoptions(options)
		
		else
			local static = m.static_link_libs and " --static " or ""
			filter "Debug"
				local pc_path = m.get_pc_path("debug")
				local result = os_capture(pc_path .. " " .. m.binary .. " --libs " .. static .. lib)
				local libs, dirs, options = parse_link_result(result)
				links(libs)
				libdirs(dirs)
				linkoptions(options)

			filter "Release"
				local pc_path = m.get_pc_path("release")
				local result = os_capture(pc_path .. " " .. m.binary .. " --libs " .. static .. lib)
				local libs, dirs, options = parse_link_result(result)
				links(libs)
				libdirs(dirs)
				linkoptions(options)

			filter { }
		end
	end

	return meths
end

return m
