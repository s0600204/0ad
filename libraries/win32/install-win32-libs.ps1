
<#
Import custom cmdlets.
#>
. .\scripts\Install-Binaries.ps1

<#
Locate dumpbin.exe

If more than one found, we use the last one (typically the most current).
#>
$HostArch = 'HostX64'
$TargetArch = 'x86'
$env:dumpbin = @(vswhere -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -find **\$HostArch\$TargetArch\dumpbin.exe)[-1]

# These should be the same as those set in build-win32-libs.ps1
$BIN_DIR             = "$PSScriptRoot\bin"
$env:BIN_DIR_RELEASE = "$BIN_DIR\release"
$env:BIN_DIR_DEBUG   = "$BIN_DIR\debug"

# These should match the paths set in build\premake\premake5.lua
$PYRO_DIR = Resolve-Path "$PSScriptRoot\..\..\binaries\system"
$env:PYRO_DIR_RELEASE = "$PYRO_DIR\release"
$env:PYRO_DIR_DEBUG   = "$PYRO_DIR\debug"


Install-Binaries -PyroPath $env:PYRO_RELEASE -PyroExe 'pyrogenesis.exe'     -BinPath $env:BIN_DIR_RELEASE
Install-Binaries -PyroPath $env:PYRO_DEBUG   -PyroExe 'pyrogenesis_dbg.exe' -BinPath $env:BIN_DIR_DEBUG
