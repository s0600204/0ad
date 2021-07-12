
<#
Run script common to both build-win32-libs.sh and install-win32-libs.sh
#>
.\scripts\common.ps1

<#
Import custom functions.
#>
. .\scripts\Expand-TarArchive.ps1
. .\scripts\Get-FileFromUrl.ps1
. .\scripts\Insert-Line.ps1
. .\scripts\Merge-ChildItems.ps1
. .\scripts\builtHandling.ps1
. .\scripts\vcpkg.ps1

<#
Locate `MSBuild.exe` and `devenv.com`.

Neither are necessarily in the `%PATH%` (notably: when building on GitHub Actions). As such,
we expect `vswhere.exe` to be (a) installed, and (b) on the %PATH%.

An alternate approach might be to download and use the `VSSetup` module for PowerShell. However
this doesn't provide as efficient way to find the components as `vswhere`.
#>
$env:devenv  = vswhere -latest -requires Microsoft.VisualStudio.Workload.NativeDesktop -find Common7\IDE\devenv.com
$env:msbuild = vswhere -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe

<#
Folder where .pc files end up.

Keep this in sync with the path set in build/workspaces/update-workspaces.sh
#>
$PC_DIR             = "$PSScriptRoot\..\source\pkgconfig"
$env:PC_DIR_RELEASE = "$PC_DIR\release"
$env:PC_DIR_DEBUG   = "$PC_DIR\debug"
if (!(Test-Path -Path $PC_DIR)) {
  New-Item -Path $PC_DIR             -ItemType Directory | Out-Null
  New-Item -Path $env:PC_DIR_RELEASE -ItemType Directory | Out-Null
  New-Item -Path $env:PC_DIR_DEBUG   -ItemType Directory | Out-Null
}

<#
Conditionally clear the folders where .dlls are placed after they're built.

@see scripts\common.ps1
#>
if ($env:force_rebuild) {
  Remove-Item -Path $env:BIN_DIR_RELEASE\* -Recurse
  Remove-Item -Path $env:BIN_DIR_DEBUG\*   -Recurse
}

<#
And finally, build the dependencies.

Most of them can be obtained via vcpkg, some are built from the bundled source, and the rest
are built by downloading and building specifically.
#>
# boost-filesystem boost-system enet fmt curl icu libiconv libpng libsodium libvorbis
# libxml2 mesa miniupnpc openal-soft opengl-registry pkgconf sdl2 wxwidgets zlib
& .\vcpkg\build.ps1

# gloox
& .\gloox\build.ps1

# FCollada
#   Req. libiconv, libxml2
& ..\source\fcollada\build.ps1

# nvtt
#   (Not available in a x86-compatible form via vcpkg at this time)
#   Req. libpng, zlib
& ..\source\nvtt\build.ps1

# spidermonkey
& ..\source\spidermonkey\build.ps1
