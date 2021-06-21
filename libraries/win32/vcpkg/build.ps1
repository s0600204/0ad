
$LIB_DIRECTORY = 'vc'

Write-Output ""
Write-Output "Acquiring dependencies from vcpkg"
Write-Output "======================================="
Push-Location $PSScriptRoot

if (!(Test-NeedsBuilding -LibVersion $VCPKG_VERSION -Path $LIB_DIRECTORY)) {
    Pop-Location
    return
}

if ($env:force_rebuild) {
    Remove-Item -Path $LIB_DIRECTORY -Recurse -ErrorAction SilentlyContinue
}

Write-Output ""
Write-Output "Build dependencies using vcpkg"
Write-Output "---------------------------------------"
New-Item -Path $LIB_DIRECTORY -ItemType Directory | Out-Null
Install-FromVCPKG `
  -InstallPath $LIB_DIRECTORY `
  -PackageList `
    'boost-algorithm', `
    'boost-filesystem', `
    'boost-flyweight', `
    'boost-lockfree', `
    'boost-random', `
    'boost-signals2', `
    'boost-system', `
    'boost-tokenizer', `
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
Merge-ChildItems -Path $BuildLocation\bin       -Destination $env:BIN_DIR_RELEASE
Merge-ChildItems -Path $BuildLocation\debug\bin -Destination $env:BIN_DIR_DEBUG

# Amend .pc files, and move them to an appropriate location
foreach ($PcFile in (Get-ChildItem -Path $BuildLocation\lib\pkgconfig).FullName) {
  $PcFileName = Split-Path -Path $PcFile -Leaf
  (Get-Content $PcFile).Replace('${pcfiledir}/../..', $BuildLocation)
    | Set-Content $env:PC_DIR_RELEASE\$PcFileName
}
foreach ($PcFile in (Get-ChildItem -Path $BuildLocation\debug\lib\pkgconfig).FullName) {
  $PcFileName = Split-Path -Path $PcFile -Leaf
  (Get-Content $PcFile).Replace('${pcfiledir}/../..', "$BuildLocation/debug")
    | Set-Content $env:PC_DIR_DEBUG\$PcFileName
}
Write-Output "Done."


Write-Output ""
Write-Output "Patch pkg-config (*.pc) files"
Write-Output "---------------------------------------"
Write-Output "-- libcurl"
(Get-Content $env:PC_DIR_RELEASE\libcurl.pc).Replace('-lcurl', '-llibcurl')
    | Set-Content $env:PC_DIR_RELEASE\libcurl.pc
(Get-Content $env:PC_DIR_DEBUG\libcurl.pc).Replace('-lcurl-d', '-llibcurl-d')
    | Set-Content $env:PC_DIR_DEBUG\libcurl.pc

Write-Output "-- OpenAL"
(Get-Content $env:PC_DIR_RELEASE\openal.pc).Replace(
    '/scripts/vcpkg/packages/openal-soft_x86-windows', "/vcpkg/$LIB_DIRECTORY/$VCPKG_TRIPLET"
  ) | Set-Content $env:PC_DIR_RELEASE\openal.pc
(Get-Content $env:PC_DIR_DEBUG\openal.pc).Replace(
    '/scripts/vcpkg/packages/openal-soft_x86-windows', "/vcpkg/$LIB_DIRECTORY/$VCPKG_TRIPLET"
  ).Replace(
    '${prefix}/include', '${prefix}/../include'
  ) | Set-Content $env:PC_DIR_DEBUG\openal.pc

Write-Output "-- SDL2"
(Get-Content $env:PC_DIR_RELEASE\sdl2.pc
    | Insert-Line -Needle 'libdir=' -Thread 'libdir2=${exec_prefix}/lib/manual-link'
  ).Replace(
    '-L"${libdir}"', '-L"${libdir}" -L"${libdir2}" -lSDL2main'
  ) | Set-Content $env:PC_DIR_RELEASE\sdl2.pc
(Get-Content $env:PC_DIR_DEBUG\sdl2.pc
    | Insert-Line -Needle 'libdir=' -Thread 'libdir2=${exec_prefix}/lib/manual-link'
  ).Replace(
    '-L"${libdir}"', '-L"${libdir}" -L"${libdir2}" -lSDL2maind'
  ) | Set-Content $env:PC_DIR_DEBUG\sdl2.pc


Write-Output ""
Write-Output "Export pkg-config executable"
Write-Output "---------------------------------------"
Copy-Item -Path $BuildLocation\tools\pkgconf\* -Destination $env:PC_DIR_RELEASE\.. -Recurse
Write-Output "Done."


Write-BuiltFile -LibVersion $VCPKG_VERSION -Path $LIB_DIRECTORY
Pop-Location
