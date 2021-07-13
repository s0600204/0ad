
Function Install-Binaries {

  param(
    [string]$PyroPath,
    [string]$PyroExe,
    [string]$BinPath
  )

  echo $PyroPath
  echo $PyroExe
  echo $BinPath

  foreach ($line in $(& $env:dumpbin /DEPENDENTS $PyroPath\$PyroExe)) {
    if ($line -notlike '*.dll') {
      continue
    }
    $dll = $line.trim()
    echo "> $dll"

    <#
    If it already exists in $PyroPath or doesn't exist in $BinPath, skip it.
    Check existence in PyroPath first as there are fewer items there to check.
    The parenthesis are needed around the first argument, else `-or` gets read as an argument of Test-Path.
    #>
    if ((Test-Path "$PyroPath\$dll") -or !(Test-Path "$BinPath\$dll")) {
      continue
    }
    echo "  copy .dll"
    Copy-Item -Path "$BinPath\$dll" -Destination "$PyroPath\$dll"

    # Copy debug symbols if they also exist
    $pdb = ($dll.split('.')[0] + '.pdb')
    if ((Test-Path "$BinPath\$pdb") -and !(Test-Path "$PyroPath\$pdb")) {
      echo "  copy .pdb"
      Copy-Item -Path "$BinPath\$pdb" -Destination "$PyroPath\$pdb"
    }
  }
}
