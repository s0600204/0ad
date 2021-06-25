
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
  -Replace '@prefix@',      '${pcfiledir}/../..' `
  -Replace '@exec_prefix@', '${prefix}' `
  -Replace '@libdir@',      '${prefix}/lib' `
  -Replace '@VERSION@',     $LIB_VERSION `
  -Replace '@LIBS@',        '' `
  -Replace '@CPPFLAGS@',    '' `
  | Set-Content $LIB_DIRECTORY\gloox.pc

New-Item -Path $env:INSTALL_DIR\include -Name 'gloox' -ItemType Directory | Out-Null
Merge-ChildItems -Path $LIB_DIRECTORY\src -Include *.h -Destination $env:INSTALL_DIR\include\gloox

Copy-Item -Path $LIB_DIRECTORY\Debug\gloox-1.0.dll -Destination $env:INSTALL_DIR\debug\bin\gloox-1.0d.dll
Copy-Item -Path $LIB_DIRECTORY\Debug\gloox-1.0.lib -Destination $env:INSTALL_DIR\debug\lib\gloox-1.0d.lib
(Get-Content $LIB_DIRECTORY\gloox.pc) `
  -Replace '@includedir@', '${prefix}/../include' `
  -Replace '-lgloox',      '-lgloox-1.0d' `
  | Set-Content $env:INSTALL_DIR\debug\lib\pkgconfig\gloox.pc

Copy-Item -Path $LIB_DIRECTORY\Release\gloox-1.0.dll -Destination $env:INSTALL_DIR\bin\
Copy-Item -Path $LIB_DIRECTORY\Release\gloox-1.0.lib -Destination $env:INSTALL_DIR\lib\
(Get-Content $LIB_DIRECTORY\gloox.pc) `
  -Replace '@includedir@', '${prefix}/include' `
  -Replace '-lgloox',      '-lgloox-1.0' `
  | Set-Content $env:INSTALL_DIR\lib\pkgconfig\gloox.pc
Write-Output "Done."


Pop-Location
