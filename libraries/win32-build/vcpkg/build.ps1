
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
$BuildLocation = Resolve-Path $LIB_DIRECTORY\$VCPKG_TRIPLET

# These should eventually end up in the same directory as .\pyrogenesis.exe
Merge-ChildItems -Path $BuildLocation\bin       -Destination $env:BIN_DIR
Merge-ChildItems -Path $BuildLocation\debug\bin -Destination $env:BIN_DIR_DEBUG

# Amend .pc files, and move them to an appropriate location
foreach ($PcFile in (Get-ChildItem -Path $BuildLocation\lib\pkgconfig).FullName) {
  $PcFileName = Split-Path -Path $PcFile -Leaf
  (Get-Content $PcFile) `
    -Replace '${pcfiledir}/../..', $BuildLocation
    | Set-Content $env:PC_DIR\$PcFileName
}
foreach ($PcFile in (Get-ChildItem -Path $BuildLocation\debug\lib\pkgconfig).FullName) {
  $PcFileName = Split-Path -Path $PcFile -Leaf
  (Get-Content $PcFile) `
    -Replace '${pcfiledir}/../..', "$BuildLocation/debug"
    | Set-Content $env:PC_DIR_DEBUG\$PcFileName
}

# Export pkg-config executable
New-Item -Path $env:INSTALL_DIR\pkgconf -ItemType Directory | Out-Null
Copy-Item -Path $BuildLocation\tools\pkgconf -Destination $env:INSTALL_DIR\pkgconf


Pop-Location
