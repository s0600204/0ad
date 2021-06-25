
Write-Output ""
Write-Output "Building nvtt"
Write-Output "======================================="
Push-Location $PSScriptRoot

# Code is pre-patched, so we don't need to apply any patches


Write-Output ""
Write-Output "Configuring Build"
Write-Output "---------------------------------------"
New-Item -Path . -Name 'build' -ItemType Directory | Out-Null
Push-Location '.\build'
cmake ..\src `
	-A Win32 `
	-DCMAKE_INSTALL_PREFIX="$PSScriptRoot\install" `
	-DPNG_PNG_INCLUDE_DIR="$env:INSTALL_DIR\include" `
	-DPNG_LIBRARY="$env:INSTALL_DIR\lib\libpng16.lib" `
	-DNVTT_SHARED="1" `
	-DZLIB_INCLUDE_DIR="$env:INSTALL_DIR\include" `
	-DZLIB_LIBRARY="$env:INSTALL_DIR\lib\zlib.lib" `
	-T "v141_xp"
Pop-Location


Write-Output ""
Write-Output "Build (Release)"
Write-Output "---------------------------------------"
New-Item -Path . -Name 'install' -ItemType Directory | Out-Null
& $env:msbuild '.\build\INSTALL.vcxproj' /p:PlatformToolset=v141_xp /p:Configuration=RelWithDebInfo


Write-Output ""
Write-Output "Export build artifacts"
Write-Output "---------------------------------------"
Merge-ChildItems -Path .\install\bin     -Destination $env:INSTALL_DIR\bin
Merge-ChildItems -Path .\install\include -Destination $env:INSTALL_DIR\include
Merge-ChildItems -Path .\install\lib     -Destination $env:INSTALL_DIR\lib


Pop-Location
