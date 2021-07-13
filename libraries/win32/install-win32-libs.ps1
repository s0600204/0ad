
<#
Run script common to both build-win32-libs.sh and install-win32-libs.sh
#>
.\scripts\common.ps1

<#
Import custom cmdlets.
#>
. .\scripts\Install-Binaries.ps1

<#
Locate dumpbin.exe

If more than one found, we use the last one (typically the most current).

Known possible values for the host architecture:
  HostX68, HostX64

Known possible values for the target architecture:
  x68, x64, arm, arm64
#>
$HostArch = 'Host' + $env:HostArchitecture.toUpper()
$env:dumpbin = @(
  vswhere -latest `
          -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
          -find **\$HostArch\$env:TargetArchitecture\dumpbin.exe
)[-1]

echo $env:dumpbin

# These should match the paths set in build\premake\premake5.lua
$PYRO_DIR = Resolve-Path "$PSScriptRoot\..\..\binaries\system"
$env:PYRO_DIR_RELEASE = "$PYRO_DIR\release"
$env:PYRO_DIR_DEBUG   = "$PYRO_DIR\debug"


Install-Binaries -PyroPath $env:PYRO_DIR_RELEASE -PyroExe 'pyrogenesis.exe'     -BinPath $env:BIN_DIR_RELEASE
Install-Binaries -PyroPath $env:PYRO_DIR_DEBUG   -PyroExe 'pyrogenesis_dbg.exe' -BinPath $env:BIN_DIR_DEBUG
