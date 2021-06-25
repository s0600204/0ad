
<#
Import custom functions.
#>
. .\scripts\Expand-TarArchive.ps1
. .\scripts\Get-FileFromUrl.ps1
. .\scripts\Merge-ChildItems.ps1
. .\scripts\vcpkg.ps1

<#
Locate `MSBuild.exe` and `devenv.com`.

Neither are necessarily in the `%PATH%` (notably: when building on GitHub Actions). As such,
we expect `vswhere.exe` to be (a) installed, and (b) on the %PATH%.

An alternate approach might be to download and use the `VSSetup` module for PowerShell. However
this doesn't provide as efficient way to find the components as `vswhere`.
#>
#~ $env:devenv  = vswhere -latest -requires Microsoft.VisualStudio.Workload.NativeDesktop -find Common7\IDE\devenv.com
#~ $env:msbuild = vswhere -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe

<#
Create a directory-tree where build artifacts are placed. (Based on the output from vcpkg.)

 $env:INSTALL_DIR
  |- bin
  |- debug
  |   |-bin
  |   '-lib
  |      '- pkgconfig
  |- include
  |- lib
  '- tools
#>
$env:INSTALL_DIR = "$PSScriptRoot\install"
Remove-Item -Path $env:INSTALL_DIR -Recurse -ErrorAction SilentlyContinue
New-Item    -Path $env:INSTALL_DIR                             -ItemType Directory | Out-Null
New-Item    -Path $env:INSTALL_DIR           -Name 'bin'       -ItemType Directory | Out-Null
New-Item    -Path $env:INSTALL_DIR           -Name 'debug'     -ItemType Directory | Out-Null
New-Item    -Path $env:INSTALL_DIR\debug     -Name 'bin'       -ItemType Directory | Out-Null
New-Item    -Path $env:INSTALL_DIR\debug     -Name 'lib'       -ItemType Directory | Out-Null
New-Item    -Path $env:INSTALL_DIR\debug\lib -Name 'pkgconfig' -ItemType Directory | Out-Null
New-Item    -Path $env:INSTALL_DIR           -Name 'include'   -ItemType Directory | Out-Null
New-Item    -Path $env:INSTALL_DIR           -Name 'lib'       -ItemType Directory | Out-Null
New-Item    -Path $env:INSTALL_DIR\lib       -Name 'pkgconfig' -ItemType Directory | Out-Null
New-Item    -Path $env:INSTALL_DIR           -Name 'tools'     -ItemType Directory | Out-Null

<#
And finally, build the dependencies.

Most of them can be obtained via vcpkg, some are built from the bundled source, and the rest
are built by downloading and building specifically.
#>
# boost-filesystem boost-system enet fmt curl icu libiconv libpng libsodium libvorbis
# libxml2 mesa miniupnpc openal-soft opengl-registry pkgconf sdl2 wxwidgets zlib
#~ & .\vcpkg\build.ps1

# gloox
#~ & .\gloox\build.ps1

# FCollada
#~ & ..\source\fcollada\build.ps1

# nvtt
# (Not available in a x86-compatible form via vcpkg at this time)
#~ & ..\source\nvtt\build.ps1

# spidermonkey
& ..\source\spidermonkey\build.ps1
