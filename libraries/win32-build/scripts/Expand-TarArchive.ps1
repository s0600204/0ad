
$7ZipLocation      = "$PSScriptRoot\7Zip"
$7ZipCache         = "$7ZipLocation\cache"
$7ZipModuleVersion = '1.13.0' # Last version to support PowerShell v2
$7ZipModule        = "$7ZipLocation\7Zip4Powershell\$7ZipModuleVersion\7Zip4PowerShell.psd1"

function Expand-TarArchive($TarArchive, $OutPath) {

	Write-Output "-- Uncompressing $TarArchive to $OutPath"

	if (-not (Get-Command Expand-7Zip -ErrorAction Ignore)) {
		if (-not (Get-Item $7ZipModule -ErrorAction Ignore)) {
			New-Item -Path $7ZipLocation -ItemType Directory | Out-Null
			Save-Module -Name 7Zip4Powershell -RequiredVersion $7ZipModuleVersion -Path $7ZipLocation
		}
		Import-Module $7ZipModule
	}

	$ArchivePath = $TarArchive
	$ArchiveName = Split-Path -Path $TarArchive -Leaf

	# Uncompress (if needed)
	$Extension = $ArchiveName.Substring($ArchiveName.LastIndexOf('.'))
	if ($Extension -ne ".tar") {
		Expand-7Zip -ArchiveFileName $TarArchive -TargetPath $7ZipCache
		$ArchiveName = $ArchiveName.Substring(0, $ArchiveName.LastIndexOf('.'))
		$ArchivePath = (Join-Path $7ZipCache $ArchiveName)
	}

	# Untar
	Expand-7Zip -ArchiveFileName $ArchivePath -TargetPath $OutPath

	# Clear cache
	if ($Extension -ne ".tar") {
		del $ArchivePath
	}
}

