
$LIB_DIRECTORY = 'src\FCollada'

Write-Output ""
Write-Output "Building FCollada"
Write-Output "======================================="
Push-Location $PSScriptRoot


Write-Output ""
Write-Output "Update build solution"
Write-Output "---------------------------------------"
& $env:devenv $LIB_DIRECTORY\FCollada.sln /Upgrade


Write-Output ""
Write-Output "Build (Debug)"
Write-Output "---------------------------------------"
& $env:msbuild $LIB_DIRECTORY\FCollada.vcxproj /v:q /t:Clean,Rebuild /p:PlatformToolset=v141_xp /p:Configuration="Debug DLL" /p:Platform="Win32"


Write-Output ""
Write-Output "Build (Release)"
Write-Output "---------------------------------------"
& $env:msbuild $LIB_DIRECTORY\FCollada.vcxproj /v:q /t:Clean,Rebuild /p:PlatformToolset=v141_xp /p:Configuration="Release DLL" /p:Platform="Win32"


Write-Output ""
Write-Output "Export build artifacts"
Write-Output "---------------------------------------"
Merge-ChildItems -Path "$LIB_DIRECTORY\Output\Release DLL Win32\FCollada" -Include *.dll,*.pdb -Destination $env:INSTALL_DIR\bin
Merge-ChildItems -Path "$LIB_DIRECTORY\Output\Debug DLL Win32\FCollada"   -Include *.dll,*.pdb -Destination $env:INSTALL_DIR\bin
Merge-ChildItems -Path $LIB_DIRECTORY                                     -Include *.h,*.hpp   -Destination $env:INSTALL_DIR\include
Merge-ChildItems -Path $LIB_DIRECTORY\Output                              -Include *.lib       -Destination $env:INSTALL_DIR\lib
Write-Output "Done."


Pop-Location
