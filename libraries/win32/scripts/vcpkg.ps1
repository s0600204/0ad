
New-Variable -Visibility Public  -Name 'VCPKG_VERSION'   -Value '2021.05.12'
New-Variable -Visibility Private -Name 'VCPKG_DIRECTORY' -Value 'vcpkg'
New-Variable -Visibility Private -Name 'VCPKG_GIT_URL'   -Value 'https://github.com/Microsoft/vcpkg.git'

<#
https://github.com/microsoft/vcpkg/tree/master/triplets

Of possible utility:
  x86-windows, x64-windows, arm-windows, arm64-windows
#>
New-Variable -Visibility Public  -Name 'VCPKG_TRIPLET'   -Value "$env:TargetArchitecture-windows"

function Install-VcpkgIfNeeded {
  if (Test-Path "$PSScriptRoot\$VCPKG_DIRECTORY") { return }

  Write-Output "-- Installing vcpkg locally"
  Push-Location $PSScriptRoot
  git clone $VCPKG_GIT_URL --branch=$VCPKG_VERSION --depth=1 $VCPKG_DIRECTORY
  & $VCPKG_DIRECTORY\bootstrap-vcpkg.bat -disableMetrics
  Pop-Location
}

function Install-FromVCPKG {
  param(
    [string[]]$PackageList,
    [string]$InstallPath
  )
  $PackageListFlattened = $PackageList -Join " "
  $InstallPathResolved = Resolve-Path -Path $InstallPath

  Install-VcpkgIfNeeded

  Write-Output "-- Building packages ($PackageListFlattened) -> $InstallPathResolved"
  & $PSScriptRoot\$VCPKG_DIRECTORY\vcpkg install `
    --triplet=$VCPKG_TRIPLET `
    --clean-buildtrees-after-build `
    --clean-packages-after-build `
    --x-install-root $InstallPathResolved `
    --keep-going `
    $PackageList
}
