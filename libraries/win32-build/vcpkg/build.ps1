
$LIB_DIRECTORY = 'vc'

Write-Output ""
Write-Output "Acquiring dependencies from vcpkg"
Write-Output "======================================="
Push-Location $PSScriptRoot


Write-Output ""
Write-Output "Build dependencies using vcpkg"
Write-Output "---------------------------------------"
New-Item -Path $LIB_DIRECTORY -ItemType Directory | Out-Null
Install-FromVCPKG `
  -InstallPath $LIB_DIRECTORY `
  -PackageList `
    'boost-filesystem', `
    'boost-system', `
    'enet', `
    'fmt', `
    'curl[core]', `
    'icu', `
    'libiconv', `
    'libpng', `
    'libsodium', `
    'libvorbis', `
    'libxml2', `
    'mesa[core,opengl]', `
    'miniupnpc', `
    'openal-soft', `
    'opengl-registry', `
    'pkgconf', `
    'sdl2', `
    'wxwidgets', `
    'zlib'


Write-Output ""
Write-Output "Export build artifacts"
Write-Output "---------------------------------------"
$BuildLocation = "$LIB_DIRECTORY\$VCPKG_TRIPLET"
Merge-ChildItems -Path $BuildLocation\bin     -Destination $env:INSTALL_DIR\bin
Merge-ChildItems -Path $BuildLocation\debug   -Destination $env:INSTALL_DIR\debug
Merge-ChildItems -Path $BuildLocation\include -Destination $env:INSTALL_DIR\include
Merge-ChildItems -Path $BuildLocation\lib     -Destination $env:INSTALL_DIR\lib
Merge-ChildItems -Path $BuildLocation\tools   -Destination $env:INSTALL_DIR\tools


Pop-Location
