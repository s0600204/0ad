function Insert-Line {

  param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [AllowEmptyString()]
      [string[]]$Haystack,

    [Parameter(Mandatory=$true)]
      [string]$Needle,

    [Parameter(Mandatory=$true)]
      [string]$Thread
  )

  PROCESS {
    return $Haystack | ForEach-Object {
      $_
      if ($_ -match $Needle) {
        $Thread
      }
    }
  }
}
