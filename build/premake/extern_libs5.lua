-- this file provides project_add_extern_libs, which takes care of the
-- dirty details of adding the libraries' include and lib paths.
--
-- TYPICAL TASK: add new library. Instructions:
-- 1) add a new extern_lib_defs entry
-- 2) add library name to extern_libs tables in premake.lua for all 'projects' that want to use it

-- directory in which OS-specific library subdirectories reside.
if os.istarget("macosx") then
	libraries_dir = rootdir.."/libraries/osx/"
elseif os.istarget("windows") then
	libraries_dir = rootdir.."/libraries/win32/"
else
	-- No Unix-specific libs yet (use source directory instead!)
end
-- directory for shared, bundled libraries
libraries_source_dir = rootdir.."/libraries/source/"
third_party_source_dir = rootdir.."/source/third_party/"

local function add_default_lib_paths(extern_lib)
	libdirs { libraries_dir .. extern_lib .. "/lib" }
end

local function add_source_lib_paths(extern_lib)
	libdirs { libraries_source_dir .. extern_lib .. "/lib" }
end

local function add_default_include_paths(extern_lib)
	sysincludedirs { libraries_dir .. extern_lib .. "/include" }
end

local function add_source_include_paths(extern_lib)
	sysincludedirs { libraries_source_dir .. extern_lib .. "/include" }
end

local function add_third_party_include_paths(extern_lib)
	sysincludedirs { third_party_source_dir .. extern_lib .. "/include" }
end

-- We use vcpkg on Windows to install most dependencies. The following two functions facilitate
-- finding the headers and libraries in the case that the dependency doesn't support pkg-config
-- (or does but vcpkg doesn't emit a .pc file for it).
local function add_vcpkg_lib_paths()
	filter "Debug"
		libdirs { libraries_dir .. "/vcpkg/vc/x86-windows/debug/lib" }
	filter "Release"
		libdirs { libraries_dir .. "/vcpkg/vc/x86-windows/lib" }
	filter { }
end
local function add_vcpkg_include_paths()
	sysincludedirs { libraries_dir .. "/vcpkg/vc/x86-windows/include" }
end

pkgconfig = require "pkgconfig"

-- Configure pkgconfig
pkgconfig.additional_pc_path_release = libraries_source_dir .. "pkgconfig/release/"
pkgconfig.additional_pc_path_debug   = libraries_source_dir .. "pkgconfig/debug/"
if os.istarget("macosx") then
	pkgconfig.additional_pc_path_release = libraries_dir .. "pkgconfig/release/"
	pkgconfig.additional_pc_path_debug   = libraries_dir .. "pkgconfig/debug/"
	pkgconfig.static_link_libs = true
elseif os.istarget("windows") then
	-- Windows' cmd.exe requires paths to be using `\` instead of `/`.
	--pkgconfig.additional_pc_path_release = string.gsub(pkgconfig.additional_pc_path_release, "/", "\\")
	--pkgconfig.additional_pc_path_debug   = string.gsub(pkgconfig.additional_pc_path_debug, "/", "\\")
	pkgconfig.binary = string.gsub(libraries_source_dir .. "pkgconfig/pkgconf.exe", "/", "\\")
end

local function add_delayload(name, suffix, def)

	if def["no_delayload"] then
		return
	end

	-- currently only supported by VC; nothing to do on other platforms.
	if not os.istarget("windows") then
		return
	end

	-- no extra debug version; use same library in all configs
	if suffix == "" then
		linkoptions { "/DELAYLOAD:"..name..".dll" }
	-- extra debug version available; use in debug config
	else
		local dbg_cmd = "/DELAYLOAD:" .. name .. suffix .. ".dll"
		local cmd     = "/DELAYLOAD:" .. name .. ".dll"

		filter "Debug"
			linkoptions { dbg_cmd }
		filter "Release"
			linkoptions { cmd }
		filter { }
	end

end

local function add_default_links(def)

	-- careful: make sure to only use *_names when on the correct platform.
	local names = {}
	if os.istarget("windows") then
		if def.win_names then
			names = def.win_names
		end
	elseif _OPTIONS["android"] and def.android_names then
		names = def.android_names
	elseif os.istarget("linux") and def.linux_names then
		names = def.linux_names
	elseif os.istarget("macosx") and (def.osx_names or def.osx_frameworks) then
		if def.osx_names then
			names = def.osx_names
		end
		-- OS X "Frameworks" are added to the links as "name.framework"
		if def.osx_frameworks then
			for i,name in pairs(def.osx_frameworks) do
				links { name .. ".framework" }
			end
		end
	elseif os.istarget("bsd") and def.bsd_names then
		names = def.bsd_names
	elseif def.unix_names then
		names = def.unix_names
	end

	local suffix = "d"
	-- library is overriding default suffix (typically "" to indicate there is none)
	if def["dbg_suffix"] then
		suffix = def["dbg_suffix"]
	end
	-- non-Windows doesn't have the distinction of debug vs. release libraries
	-- (to be more specific, they do, but the two are binary compatible;
	-- usually only one type - debug or release - is installed at a time).
	if not os.istarget("windows") then
		suffix = ""
	end

	for i,name in pairs(names) do
		filter "Debug"
			links { name .. suffix }
		filter "Release"
			links { name }
		filter { }

		add_delayload(name, suffix, def)
	end

end

-- Library definitions
-- In a perfect world, libraries would have a common installation template,
-- i.e. location of include directory, naming convention for .lib, etc.
-- this table provides a means of working around each library's differences.
--
-- The basic approach is defining two functions per library:
--
-- 1. compile_settings
-- This function should set all settings requred during the compile-phase like
-- includedirs, defines etc...
--
-- 2. link_settings
-- This function should set all settings required during the link-phase like
-- libdirs, linkflag etc...
--
-- The main reason for separating those settings is different linking behaviour
-- on osx and xcode. For more details, read the comment in project_add_extern_libs.
--
-- There are some helper functions for the most common tasks. You should use them
-- if they can be used in your situation to make the definitions more consistent and
-- use their default beviours as a guideline.
--
--
-- add_default_lib_paths(extern_lib)
--      Description: Add '<libraries root>/<libraryname>/lib'to the libpaths
--      Parameters:
--          * extern_lib: <libraryname> to be used in the libpath.
--
-- add_default_include_paths(extern_lib)
--      Description: Add '<libraries root>/<libraryname>/include' to the includepaths
--      Parameters:
--          * extern_lib: <libraryname> to be used in the libpath.
--
-- add_default_links
--      Description: Adds links to libraries and configures delayloading.
--      If the *_names parameter for a plattform is missing, no linking will be done
--      on that plattform.
--      The default assumptions are:
--      * debug import library and DLL are distinguished with a "d" suffix
--      * the library should be marked for delay-loading.
--      Parameters:
--      * win_names: table of import library / DLL names (no extension) when
--        running on Windows.
--      * unix_names: as above; shared object names when running on non-Windows.
--      * osx_names, osx_frameworks: for OS X specifically; if any of those is
--        specified, unix_names is ignored. Using both is possible if needed.
--          * osx_names: as above.
--          * osx_frameworks: as above, for system libraries that need to be linked
--            as "name.framework".
--      * bsd_names: as above; for BSD specifically (overrides unix_names if both are
--        specified)
--      * linux_names: ditto for Linux (overrides unix_names if both given)
--      * dbg_suffix: changes the debug suffix from the above default.
--        can be "" to indicate the library doesn't have a debug build;
--        in that case, the same library (without suffix) is used in
--        all build configurations.
--      * no_delayload: indicate the library is not to be delay-loaded.
--        this is necessary for some libraries that do not support it,
--        e.g. Xerces (which is so stupid as to export variables).

extern_lib_defs = {
	boost = {
		compile_settings = function()
			if os.istarget("windows") then
				add_vcpkg_include_paths()
			elseif os.istarget("macosx") then
				-- Suppress all the Boost warnings on OS X by including it as a system directory
				buildoptions { "-isystem../" .. libraries_dir .. "boost/include" }
			end
			-- TODO: This actually applies to most libraries we use on BSDs, make this a global setting.
			if os.istarget("bsd") then
				sysincludedirs { "/usr/local/include" }
			end
		end,
		link_settings = function()
			if os.istarget("windows") then
				-- boost has an "autolinker" that links the appropriate .lib files through use
				-- of `#pragma comment(lib)`. Unfortunately vcpkg disables it, requiring
				-- us to specify the libs we want to link against.
				-- (https://github.com/microsoft/vcpkg/blob/master/ports/boost-config/portfile.cmake)
				local toolset = "vc140"
				add_vcpkg_lib_paths()
				add_default_links({
					win_names = { "boost_filesystem-"..toolset.."-mt", "boost_system-"..toolset.."-mt" },
					dbg_suffix = "-gd",
					no_delayload = 1,
				})
			elseif os.istarget("macosx") then
				add_default_lib_paths("boost")
			end
			add_default_links({
				-- The following are not strictly link dependencies on all systems, but
				-- are included for compatibility with different versions of Boost
				android_names = { "boost_filesystem-gcc-mt", "boost_system-gcc-mt" },
				unix_names = { os.findlib("boost_filesystem-mt") and "boost_filesystem-mt" or "boost_filesystem", os.findlib("boost_system-mt") and "boost_system-mt" or "boost_system" },
				osx_names = { "boost_filesystem", "boost_system" },
			})
		end,
	},
	comsuppw = {
		link_settings = function()
			add_default_links({
				win_names = { "comsuppw" },
				dbg_suffix = "d",
				no_delayload = 1,
			})
		end,
	},
	cxxtest = {
		compile_settings = function()
			sysincludedirs { libraries_source_dir .. "cxxtest-4.4" }
		end,
	},
	enet = {
		compile_settings = function()
			if os.istarget("windows") then
				-- vcpkg doesn't emit a .pc file for this dependency :(
				add_vcpkg_include_paths()
			else
				pkgconfig.find_system("libenet").add_includes()
			end
		end,
		link_settings = function()
			if os.istarget("windows") then
				-- vcpkg doesn't emit a .pc file for this dependency :(
				add_vcpkg_lib_paths()
				add_default_links({
					win_names  = { "enet", "ws2_32", "winmm" },
					dbg_suffix = "",
					no_delayload = 1,
				})
			else
				pkgconfig.find_system("libenet").add_links()
			end
		end,
	},
	fcollada = {
		compile_settings = function()
			add_source_include_paths("fcollada")
		end,
		link_settings = function()
			add_source_lib_paths("fcollada")
			if os.istarget("windows") then
				filter "Debug"
					links { "FColladaD" }
				filter "Release"
					links { "FCollada" }
				filter { }
			else
				filter "Debug"
					links { "FColladaSD" }
				filter "Release"
					links { "FColladaSR" }
				filter { }
			end
		end,
	},
	fmt = {
		compile_settings = function()
			if os.istarget("windows") or os.istarget("macosx") then
				pkgconfig.find_system("fmt").add_includes()
			end

			-- With Linux & BSD, we assume that fmt is installed in a standard location.
			--
			-- It would be nice to not assume, and to instead use pkg-config: however that
			-- requires fmt 5.3.0 or greater.
			--
			-- Unfortunately (at the time of writing) only 81 out of 104 (~77.9%) of distros
			-- that provide a fmt package meet this, according to
			-- https://repology.org/badge/vertical-allrepos/fmt.svg?minversion=5.3
			--
			-- Whilst that might seem like a healthy majority, this does not include the 2018
			-- Long Term Support and 2019.10 releases of Ubuntu - not only popular and widely
			-- used as-is, but which are also used as a base for other popular distros (e.g.
			-- Mint).
			--
			-- When fmt 5.3 (or better) becomes more widely used, then we can safely use the
			-- same line as we currently use for osx
		end,
		link_settings = function()
			if os.istarget("windows") or os.istarget("macosx") then
				-- See comment above as to why this is not also used on Linux or BSD.
				pkgconfig.find_system("fmt").add_links()
			else
				add_default_links({
					unix_names = { "fmt" },
				})
			end
		end
	},
	gloox = {
		compile_settings = function()
			pkgconfig.find_system("gloox").add_includes()
		end,
		link_settings = function()
			pkgconfig.find_system("gloox").add_links()

			if os.istarget("macosx") then
				-- gloox depends on gnutls, but doesn't identify this via pkg-config
				pkgconfig.find_system("gnutls").add_links()
			end
		end,
	},
	iconv = {
		compile_settings = function()
			if os.istarget("windows") then
				add_vcpkg_include_paths()
				defines { "HAVE_ICONV_CONST" }
				defines { "ICONV_CONST=const" }
				defines { "LIBICONV_STATIC" }
			elseif os.istarget("macosx") then
				add_default_include_paths("iconv")
				defines { "LIBICONV_STATIC" }
			elseif os.getversion().description == "FreeBSD" then
				-- On FreeBSD you need this flag to tell it to use the BSD libc iconv
				defines { "LIBICONV_PLUG" }
			end
		end,
		link_settings = function()
			if os.istarget("windows") then
				add_vcpkg_lib_paths()
			elseif os.istarget("macosx") then
				add_default_lib_paths("iconv")
			end
			add_default_links({
				win_names  = { "iconv" },
				osx_names = { "iconv" },
				dbg_suffix = "",
				no_delayload = 1,
			})
			-- glibc (used on Linux and GNU/kFreeBSD) has iconv
		end,
	},
	icu = {
		compile_settings = function()
			pkgconfig.find_system("icu-i18n").add_includes()
		end,
		link_settings = function()
			pkgconfig.find_system("icu-i18n").add_links()
		end,
	},
	libcurl = {
		compile_settings = function()
			pkgconfig.find_system("libcurl").add_includes()
		end,
		link_settings = function()
			pkgconfig.find_system("libcurl").add_links()
			add_default_links({
				osx_frameworks = { "Security" }, -- Not supplied by curl's pkg-config
			})
		end,
	},
	libpng = {
		compile_settings = function()
			pkgconfig.find_system("libpng").add_includes()
		end,
		link_settings = function()
			pkgconfig.find_system("libpng").add_links()
		end,
	},
	libsodium = {
		compile_settings = function()
			if os.istarget("windows") then
				-- vcpkg doesn't emit a .pc file for this dependency :(
				add_vcpkg_include_paths()
			else
				pkgconfig.find_system("libsodium").add_includes()
			end
		end,
		link_settings = function()
			if os.istarget("windows") then
				-- vcpkg doesn't emit a .pc file for this dependency :(
				add_vcpkg_lib_paths()
				add_default_links({
					win_names  = { "libsodium" },
					dbg_suffix = "",
				})
			else
				pkgconfig.find_system("libsodium").add_links()
			end
		end,
	},
	libxml2 = {
		compile_settings = function()
			pkgconfig.find_system("libxml-2.0").add_includes()

			if os.istarget("macosx") then
				-- libxml2 needs _REENTRANT or __MT__ for thread support;
				-- OS X doesn't get either set by default, so do it manually
				defines { "_REENTRANT" }
			end
		end,
		link_settings = function()
			pkgconfig.find_system("libxml-2.0").add_links()
		end,
	},
	miniupnpc = {
		compile_settings = function()
			if os.istarget("windows") then
				-- vcpkg doesn't emit a .pc file for this dependency :(
				add_vcpkg_include_paths()
			elseif os.istarget("macosx") then
				pkgconfig.find_system("miniupnpc").add_includes()
			end

			-- On Linux and BSD systems we assume miniupnpc is installed in a standard location.
			--
			-- Support for pkg-config was added in v2.1 of miniupnpc (May 2018). However, the
			-- implementation was flawed - it provided the wrong path to the project's headers.
			-- This was corrected in v2.2.1 (December 2020).
			--
			-- At the time of writing, of the 115 Linux and BSD package repositories tracked by
			-- Repology that supply a version of miniupnpc:
			-- * 77 (~67.96%) have >= v2.1, needed to locate libraries
			-- * 31 (~26.96%) have >= v2.2.1, needed to (correctly) locate headers
			--
			-- Once more recent versions become more widespread, we can safely start to use
			-- pkg-config to find miniupnpc on Linux and BSD systems.
			-- https://repology.org/badge/vertical-allrepos/miniupnpc.svg?minversion=2.2.1
		end,
		link_settings = function()
			if os.istarget("windows") then
				-- vcpkg doesn't emit a .pc file for this dependency :(
				add_vcpkg_lib_paths()
				add_default_links({
					win_names  = { "miniupnpc" },
					dbg_suffix = "",
				})
			elseif os.istarget("macosx") then
				pkgconfig.find_system("miniupnpc").add_links()
			else
				-- Once miniupnpc v2.1 or better becomes near-universal (see above comment),
				-- we can use pkg-config for Linux and BSD.
				add_default_links({
					unix_names = { "miniupnpc" },
				})
			end
		end,
	},
	nvtt = {
		compile_settings = function()
			if not _OPTIONS["with-system-nvtt"] then
				add_source_include_paths("nvtt")
			end
			defines { "NVTT_SHARED=1" }
		end,
		link_settings = function()
			if not _OPTIONS["with-system-nvtt"] then
				add_source_lib_paths("nvtt")
			end
			add_default_links({
				win_names  = { "nvtt" },
				unix_names = { "nvcore", "nvmath", "nvimage", "nvtt" },
				osx_names = { "bc6h", "bc7", "nvcore", "nvimage", "nvmath", "nvthread", "nvtt", "squish" },
				dbg_suffix = "", -- for performance we always use the release-mode version
			})
		end,
	},
	openal = {
		compile_settings = function()
			if not os.istarget("macosx") then
				pkgconfig.find_system("openal").add_includes()
			end
		end,
		link_settings = function()
			if os.istarget("macosx") then
				add_default_links({
					osx_frameworks = { "OpenAL" },
				})
			else
				pkgconfig.find_system("openal").add_links()
			end
		end,
	},
	opengl = {
		-- On MacOS: OpenGL comes from Apple (and has been deprecated).
		-- On Windows: headers come from the Kronos Group's opengl-registry; libs from Mesa3D.
		-- On Linux: OpenGL comes from Mesa3D and libglvnd.
		--
		-- In April 2019, pkg-config support was moved from Mesa3D to libglvnd
		-- (mesa 19.1 & libglvnd 1.2).
		--
		-- Mesa3D is still capable of providing a .pc file for OpenGL - but only on Android.
		compile_settings = function()
			if os.istarget("windows") then
				add_vcpkg_include_paths()
			elseif _OPTIONS["gles"] then
				pkgconfig.find_system("glesv2").add_includes()
			elseif not os.istarget("macosx") then
				pkgconfig.find_system("gl").add_includes()
			end
		end,
		link_settings = function()
			if os.istarget("windows") then
				-- Use `links` directly as we don't want delayload or a dbg_suffix
				add_vcpkg_lib_paths()
				links { "opengl32", "gdi32", }
			elseif os.istarget("macosx") then
				add_default_links({
					osx_frameworks = { "OpenGL" },
				})
			elseif _OPTIONS["gles"] then
				pkgconfig.find_system("glesv2").add_links()
			else
				pkgconfig.find_system("gl").add_links()
			end
		end,
	},
	sdl = {
		compile_settings = function()
			if not _OPTIONS["android"] then
				pkgconfig.find_system("sdl2").add_includes()
			end
		end,
		link_settings = function()
			if not _OPTIONS["android"] then
				pkgconfig.find_system("sdl2").add_links()
			end
		end,
	},
	spidermonkey = {
		compile_settings = function()
			if _OPTIONS["with-system-mozjs"] then
				if not _OPTIONS["android"] then
					pkgconfig.find_system("mozjs-78").add_includes()
				end
			else
				pkgconfig.find_system("mozjs78-ps").add_includes()
			end
		end,
		link_settings = function()
			if _OPTIONS["with-system-mozjs"] then
				if _OPTIONS["android"] then
					links { "mozjs-78" }
				else
					pkgconfig.find_system("mozjs-78").add_links()
				end
			else
				pkgconfig.find_system("mozjs78-ps").add_links()
			end

		end,
	},
	tinygettext = {
		compile_settings = function()
			add_third_party_include_paths("tinygettext")
		end,
	},
	valgrind = {
		compile_settings = function()
			add_source_include_paths("valgrind")
		end,
	},
	vorbis = {
		compile_settings = function()
			pkgconfig.find_system("ogg").add_includes()
			pkgconfig.find_system("vorbisfile").add_includes()
		end,
		link_settings = function()
			if os.getversion().description == "OpenBSD" then
				-- TODO: We need to force linking with these as currently
				-- they need to be loaded explicitly on execution
				add_default_links({
					unix_names = { "ogg", "vorbis" },
				})
			else
				pkgconfig.find_system("vorbisfile").add_links()
			end
		end,
	},
	wxwidgets = {
		compile_settings = function()
			if os.istarget("windows") then
				add_vcpkg_include_paths()
			else
				-- wxwidgets does not come with a definition file for pkg-config,
				-- so we have to use wxwidgets' own config tool
				wx_config_path = os.getenv("WX_CONFIG") or "wx-config"
				pkgconfig.find_system(nil, wx_config_path).add_includes("--unicode=yes --cxxflags")
			end
		end,
		link_settings = function()
			if os.istarget("windows") then
				-- When being used within a project being built with MSVC, wxWidgets ordinarily
				-- uses `#pragma comment(lib)` to specify libs to link against. Annoyingly,
				-- vcpkg removes the header file that facilitates this. Thus we must manually
				-- specify the libs we need.
				add_vcpkg_lib_paths()
				filter "Debug"
					links { "wxbase31ud", "wxbase31ud_xml", "wxmsw31ud_core", "wxmsw31ud_gl", }
				filter "Release"
					links { "wxbase31u", "wxbase31u_xml", "wxmsw31u_core", "wxmsw31u_gl", }
				filter { }
			else
				wx_config_path = os.getenv("WX_CONFIG") or "wx-config"
				pkgconfig.find_system(nil, wx_config_path).add_links("--unicode=yes --libs std,gl")
			end
		end,
	},
	x11 = {
		compile_settings = function()
			if not os.istarget("windows") and not os.istarget("macosx") then
				pkgconfig.find_system("x11").add_includes()
			end
		end,
		link_settings = function()
			if not os.istarget("windows") and not os.istarget("macosx") then
				pkgconfig.find_system("x11").add_links()
			end
		end,
	},
	zlib = {
		compile_settings = function()
			pkgconfig.find_system("zlib").add_includes()
		end,
		link_settings = function()
			pkgconfig.find_system("zlib").add_links()
		end,
	},
}


-- add a set of external libraries to the project; takes care of
-- include / lib path and linking against the import library.
-- extern_libs: table of library names [string]
-- target_type: String defining the projects kind [string]
function project_add_extern_libs(extern_libs, target_type)

	for i,extern_lib in pairs(extern_libs) do
		local def = extern_lib_defs[extern_lib]
		assert(def, "external library " .. extern_lib .. " not defined")

		if def.compile_settings then
			def.compile_settings()
		end

		-- Linking to external libraries will only be done in the main executable and not in the
		-- static libraries. Premake would silently skip linking into static libraries for some
		-- actions anyway (e.g. vs2010).
		-- On osx using xcode, if this linking would be defined in the static libraries, it would fail to
		-- link if only dylibs are available. If both *.a and *.dylib are available, it would link statically.
		-- I couldn't find any problems with that approach.
		if target_type ~= "StaticLib" and def.link_settings then
			def.link_settings()
		end
	end
end
