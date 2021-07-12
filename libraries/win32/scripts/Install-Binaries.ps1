
Function Install-Binaries {

  param(
    [string]$PyroPath,
    [string]$PyroExe,
    [string]$BinPath
  )

  & $env:dumpbin /DEPENDENTS $PyroPath\$PyroExe | ForEach-Object {
    if ($_ -like '*.dll') {
      $dll = $_.trim()

      <#
      If it already exists in $PyroPath or doesn't exist in $BinPath, skip it.
      The parenthesis are needed, else `-or` gets read as an argument of Test-Path.
      Check existence in PyroPath first as there are fewer items there to check.
      #>
      if ((Test-Path $PyroPath\$dll) -or !(Test-Path $BinPath\$dll)) {
        continue
      }
      Copy-Item -Path $BinPath\$dll -Destination $PyroPath\$dll

      # Copy debug symbols if they also exist
      $pdb = ($dll.split('.')[0] + '.pdb')
      if ((Test-Path $BinPath\$pdb) -and !(Test-Path $PyroPath\$pdb)) {
        Copy-Item -Path $BinPath\$pdb -Destination $PyroPath\$pdb
      }
    }
  }
}
