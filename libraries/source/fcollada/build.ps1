
$LIB_VERSION = 'fcollada-3.05+wildfiregames.6'
$LIB_DIRECTORY = 'src\FCollada'

Write-Output ""
Write-Output "Building FCollada ($LIB_VERSION)"
Write-Output "======================================="
Push-Location $PSScriptRoot

if (!(Test-NeedsBuilding -LibVersion $LIB_VERSION)) {
  Pop-Location
  return
} else {
  Remove-Item -Path .\src\output -Recurse -ErrorAction SilentlyContinue
  Remove-Item -Path .\lib        -Recurse -ErrorAction SilentlyContinue
}


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
Merge-ChildItems -Path "$LIB_DIRECTORY\Output\Release DLL Win32\FCollada" -Include *.dll,*.pdb -Destination $env:BIN_DIR_RELEASE
Merge-ChildItems -Path "$LIB_DIRECTORY\Output\Debug DLL Win32\FCollada"   -Include *.dll,*.pdb -Destination $env:BIN_DIR_DEBUG

New-Item -Path $PSScriptRoot -Name 'lib' -ItemType Directory | Out-Null
foreach ($Item in (Get-ChildItem -Path ".\$LIB_DIRECTORY\Output\*" -Include *.lib)) {
  Copy-Item -Path $Item.FullName -Destination $PSScriptRoot\lib
}
Write-Output "Done."


Write-BuiltFile -LibVersion $LIB_VERSION
Pop-Location
