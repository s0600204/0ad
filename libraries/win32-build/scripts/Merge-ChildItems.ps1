
function Merge-ChildItems
{
	param(
		[Parameter(Mandatory=$true)][string]$Path,
		[Parameter(Mandatory=$true)][string]$Destination,
		[Parameter(Mandatory=$false)][string[]]$Include
	)

	if (!(Test-Path -Path $Path)) {
		Write-Output "/!\ Source ($Path) does not exist."
		return
	}
	elseif (!(Test-Path -Path $Destination)) {
		Write-Output "/!\ Destination ($Destination) does not exist."
		return
	}

	$AbsPath        = Resolve-Path $Path
	$AbsDestination = Resolve-Path $Destination

	if ($Include) {
		$Items = Get-ChildItem -Path $Path -Recurse -Include $Include
	} else {
		$Items = Get-ChildItem -Path $Path -Recurse
	}

	foreach($Item in $Items)
	{
		# Skip directories
		if ($Item -is [System.IO.DirectoryInfo]) {
			continue
		}

		$SourcePath = $Item.FullName
		$TargetPath = $SourcePath.Replace($AbsPath.Path, $AbsDestination.Path)

		# Create the path to the file if it doesn't already exist
		$TargetParent = Split-Path $TargetPath -Parent
		if (!(Test-Path $TargetParent)) {
			New-Item -Path $TargetParent -ItemType Directory | Out-Null
		}

		Copy-Item -Path $SourcePath -Destination $TargetPath
	}
}
