
function Get-FileFromUrl($FileName, $Url) {

	$FilePath = Join-Path -Path (Resolve-Path -Path .).Path -ChildPath $FileName
	Write-Output "-- Downloading $Url -> $FilePath"

	if (Get-Command Invoke-WebRequest -ErrorAction Ignore)
	{
		# PowerShell 5.1+
		Invoke-WebRequest -Uri $Url -Method Get -OutFile $FilePath
	}
	else
	{
		$WebClient = New-Object System.Net.WebClient
		$WebClient.DownloadFile($Url, $FilePath)
	}
}
