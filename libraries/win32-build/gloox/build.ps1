
$LIB_VERSION   = '1.0.24'
$LIB_ARCHIVE   = "gloox-$LIB_VERSION.tar.bz2"
$LIB_DIRECTORY = "gloox-$LIB_VERSION"
$LIB_URL       = "http://camaya.net/download/$LIB_ARCHIVE"

Write-Output ""
Write-Output "Building gloox"
Write-Output "======================================="
Push-Location $PSScriptRoot


Write-Output ""
Write-Output "Acquire source"
Write-Output "---------------------------------------"
Get-FileFromUrl -FileName $LIB_ARCHIVE -Url $LIB_URL
Expand-TarArchive -TarArchive $LIB_ARCHIVE -OutPath .


Write-Output ""
Write-Output "Patch source"
Write-Output "---------------------------------------"
Get-Content .\vcproj.patch | patch -p1


Write-Output ""
Write-Output "Update project file"
Write-Output "---------------------------------------"
& $env:devenv $LIB_DIRECTORY\gloox.vcproj /Upgrade


Write-Output ""
Write-Output "Build (Debug)"
Write-Output "---------------------------------------"
& $env:msbuild $LIB_DIRECTORY\gloox.vcxproj /p:PlatformToolset=v141_xp /p:Configuration=Debug


Write-Output ""
Write-Output "Build (Release)"
Write-Output "---------------------------------------"
& $env:msbuild $LIB_DIRECTORY\gloox.vcxproj /p:PlatformToolset=v141_xp /p:Configuration=Release


Write-Output ""
Write-Output "Export build artifacts"
Write-Output "---------------------------------------"
(Get-Content $LIB_DIRECTORY\gloox.pc.in) `
  -Replace '@prefix@',      (Resolve-Path $LIB_DIRECTORY) `
  -Replace '@exec_prefix@', '${prefix}' `
  -Replace '@libdir@',      '${prefix}/lib' `
  -Replace '@includedir@',  '${prefix}/include' `
  -Replace '@VERSION@',     $LIB_VERSION `
  -Replace '@LIBS@',        '' `
  -Replace '@CPPFLAGS@',    '' `
  | Set-Content $LIB_DIRECTORY\gloox.pc

Copy-Item -Path $LIB_DIRECTORY\Debug\gloox-1.0.dll -Destination $env:BIN_DIR_DEBUG\gloox-1.0d.dll
(Get-Content $LIB_DIRECTORY\gloox.pc) `
  -Replace '-lgloox',      '-lgloox-1.0d' `
  | Set-Content $env:PC_DIR\gloox.pc

Copy-Item -Path $LIB_DIRECTORY\Release\gloox-1.0.dll -Destination $env:BIN_DIR
(Get-Content $LIB_DIRECTORY\gloox.pc) `
  -Replace '-lgloox',      '-lgloox-1.0' `
  | Set-Content $env:PC_DIR_DEBUG\gloox.pc

Write-Output "Done."


Pop-Location
