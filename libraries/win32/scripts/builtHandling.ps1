
New-Variable -Visibility Private -Name 'BuiltCheckFilename' -Value '.already-built'

function Test-NeedsBuilding {
  param(
    [Parameter(Mandatory=$true)]
      [string]$LibVersion,

    [Parameter(Mandatory=$false)]
      [string]$Path=$null
  )

  if ($env:force_rebuild) {
    Write-Output "-- Rebuild requested"
    return $true
  }

  if (Test-Path $Path) {
    $AbsolutePath = Resolve-Path $Path
  } else {
    $AbsolutePath = Resolve-Path .
  }

  if (!(Test-Path "$AbsolutePath\$BuiltCheckFilename")) {
    return $true
  }

  if ((Get-Content -Path $AbsolutePath\$BuiltCheckFilename) -eq $LibVersion) {
    Write-Output "-- Already built"
    return $false
  }
  return $true
}

function Write-BuiltFile {
  param(
    [Parameter(Mandatory=$true)]
      [string]$LibVersion,

    [Parameter(Mandatory=$false)]
      [string]$Path=$null
  )

  if (Test-Path $Path) {
    $AbsolutePath = Resolve-Path $Path
  } else {
    $AbsolutePath = Resolve-Path .
  }

  if (Test-Path "$AbsolutePath\$BuiltCheckFilename") {
    Remove-Item -Path $AbsolutePath\$BuiltCheckFilename
  }

  New-Item -Path $AbsolutePath\$BuiltCheckFilename -Value $LIB_VERSION | Out-Null
}
