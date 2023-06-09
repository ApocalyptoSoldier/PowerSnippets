<#
.Synopsis 
	Gets the paths to windows special folders, eg. Desktop, MyDocuments
.Parameter Name
	Filters results by special folder names
.Parameter ListAvailable
	Shows all special folders where the folder actually exists
.Example
	PS> Get-SpecialFolder 'My*'
	
	Name        Path
	----        ----
	MyComputer
	MyDocuments C:\Users\user\OneDrive\Documents
	MyMusic     C:\Users\user\Music
	MyPictures  C:\Users\user\OneDrive\Pictures
	MyVideos    C:\Users\user\Videos
#>
Function Get-SpecialFolder()
{
	[CmdletBinding(DefaultParameterSetName = 'Filter')]
	param(
		[Parameter(ParameterSetName='Filter', Position=0)]
		[string]$Name = '*',
		[Parameter(ParameterSetName='ListAvailable', Position=0)]
		[switch]$ListAvailable
		)
		
	$specialFolderNames = [Enum]::GetNames('System.Environment+SpecialFolder') | Sort
	$specialFolders = [System.Collections.ArrayList]@()
	
	foreach ($specialFolderName in $specialFolderNames)
	{
		$specialFolders.Add([PSCustomObject]@{
			Name = $specialFolderName
			Path = [Environment]::GetFolderPath($specialFolderName)
		}) | Out-Null
	}
	if ($ListAvailable)
	{
		return $specialFolders | Where { Test-Path $_.Path }
	}
	else
	{
		return $specialfolders | Where Name -Like $Name
	}
}