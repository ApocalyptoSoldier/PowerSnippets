<#
.Synopsis 
	Gets the paths to windows shell folders, eg. shell:Startup, shell:SendTo, shell:Downloads
.Parameter Name
	Filters results by shell folder names
#>
function Get-ShellFolder()
{
	# Inspired by https://www.robvanderwoude.com/powershellsnippets.php#ListShellFolders
	param([string]$Name = '*')	
	
	$shellFolderDescriptions = Get-ChildItem 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\explorer\FolderDescriptions' | Get-ItemProperty | Sort Name
	$controlPanelFolder = $shellFolderDescriptions | Where Name -EQ 'ControlPanelFolder'
	
	$shellFolderDescriptions = $shellFolderDescriptions | Where -Property Name -Like $Name
	
	$shellFolders = [System.Collections.ArrayList]@()
		
	foreach ($folderDescription in $shellFolderDescriptions)
	{
		if ($controlPanelFolder.ParsingName -in $folderDescription.ParsingName)
		{
			Write-Debug "$($folderDescription.Name) is a control panel item"
			continue
		}
		
		$shellFolderPath = ''
		
		# These point to files which then point to the actual locations
		if ($folderDescription.STREAMRESOURCETYPE -eq 'LIBRARY')
		{
			$libraryFilePath = Get-KnownFolderPath $folderDescription.PSChildName
			
			if (-not $libraryFilePath)
			{
				continue
			}
			
			$libraryLocations = Get-LibrarySimpleLocations $libraryFilePath | Where { Test-Path $_ }
			
			# A library can include multiple locations, but this function returns one path per shell folder
			$shellFolderPath = $libraryLocations | Select -First 1
		}
		else
		{
			$shellFolderPath = Get-KnownFolderPath $folderDescription.PSChildName
			
			if (-not $shellFolderPath)
			{
				if (-not $folderDescription.ParentFolder)
				{
					continue
				}
				
				$shellFolderParent = Get-KnownFolderPath $folderDescription.ParentFolder
				
				$shellFolderPath = Join-Path $shellFolderParent $folderDescription.RelativePath
			}
		}
		
		if ($shellFolderPath)
		{
			$shellFolders.Add([PSCustomObject]@{
				Name = $folderDescription.Name
				Path = $shellFolderPath
			}) | Out-Null
		}
	}
	
	return $shellFolders
}

<#
.Synopsis
	Gets libraries and all locations included in them as defined in the *.library-ms files, eg. Music, Pictures
.Parameter Name
	Filters results by library names
.Example
	PS> Get-LibraryFolder MusicLibrary
	
	Name         IncludedLocations
	----         ---------
	MusicLibrary C:\Users\user\Music
#>
function Get-LibraryFolder()
{
	param([string]$Name = '*')
	
	$shellFolderDescriptions = Get-ChildItem 'HKLM:SOFTWARE\Microsoft\Windows\CurrentVersion\explorer\FolderDescriptions' | Get-ItemProperty | Sort Name
	$shellFolderDescriptions = $shellFolderDescriptions | Where -Property Name -Like $Name
	$shellFolderDescriptions = $shellFolderDescriptions | Where -Property STREAMRESOURCETYPE -Eq 'Library'
	
	$libraries = [System.Collections.ArrayList]@()
	
	foreach ($folderDescription in $shellFolderDescriptions)
	{
		$libraryFilePath = Get-KnownFolderPath $folderDescription.PSChildName
		if (-not $libraryFilePath)
		{
			continue
		}
		$libraryLocations = Get-LibrarySimpleLocations $libraryFilePath | Where { Test-Path $_ }
		
		$libraries.Add([PSCustomObject]@{
			Name = $folderDescription.Name
			IncludedLocations = $libraryLocations
		}) | Out-Null
	}
	
	return $libraries
}

<#
.Synopsis
	Gets the path to a windows known folder by it's KNOWNFOLDERID
.Parameter KnownFolderId
	The KNOWNFOLDERID or a string containing said id
.Notes
	Nothing will be returned if the actaul folder doesn't physically exist
	
	API documentation: https://learn.microsoft.com/en-us/windows/win32/api/shlobj_core/nf-shlobj_core-shgetknownfolderpath
	List of KNOWNFOLDERIDs: https://learn.microsoft.com/en-us/previous-versions/bb762584(v=vs.85)
#>
function Get-KnownFolderPath()
{
	# Original function by u/rmbolger from https://www.reddit.com/r/PowerShell/comments/12zh5uh/comment/jhst9rq/
	param(
		[Parameter(Mandatory=$true)]
		[string]$KnownFolderId
		)
	
	$hasValidGuid = $KnownFolderId -match '[\da-f]{8}-[\da-f]{4}-[\da-f]{4}-[\da-f]{4}-[\da-f]{12}'
	if (-not $hasValidGuid)
	{
		Write-Debug "Could not extract KNOWNFOLDERID from $KnownFolderId"
		return
	}
	
    $KnownFolderId = $Matches[0]	

	$GetSignature = @'
        [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
		public extern static int SHGetKnownFolderPath(
        ref Guid folderId,
        uint flags,
        IntPtr token,
        out IntPtr pszProfilePath);
'@
	$GetType = Add-Type -MemberDefinition $GetSignature -Name 'GetKnownFolders' -Namespace 'SHGetKnownFolderPath' -Using "System.Text" -PassThru -ErrorAction SilentlyContinue
	
    $ptr = [intptr]::Zero
    [void]$GetType::SHGetKnownFolderPath([Ref]"$KnownFolderId", 0, 0, [ref]$ptr)
    $result = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
    [System.Runtime.InteropServices.Marshal]::FreeCoTaskMem($ptr)
    return $result
}

<#
.Synopsis
	Gets all included locations from a *.library-ms file
.Parameter LibraryFilePath
	The path to the *.library-ms file
.Example
	PS> Get-LibrarySimpleLocations 'C:\Users\user\AppData\Roaming\Microsoft\Windows\Libraries\Music.library-ms'
	
	C:\Users\user\Music
	D:\Music
#>
function Get-LibrarySimpleLocations()
{
	param(
		[Parameter(Mandatory=$true)]
		[string]$LibraryFilePath
	)
	
	if (-not (Test-Path $LibraryFilePath))
	{
		return $null
	}
	
	$librarySimpleLocations = @()

	$libraryXml = [xml](Get-Content $LibraryFilePath)
	# These files have a 'xmlns' attribute, so we need a namespace manager to get XPath queries to work
	$nsm = New-Object System.Xml.XmlNamespaceManager($libraryXml.NameTable)
	$nsm.AddNamespace('ns', $libraryXml.DocumentElement.NamespaceURI)
	
	$urlNodes = $libraryXml.SelectNodes('//ns:simpleLocation/ns:url', $nsm)
	
	foreach ($urlNode in $urlNodes)
	{
		$nestedShellMatch = [regex]::Match($urlNode.InnerText, 'shell:(?<ParentShellFolder>[\w\s]+)\\(?<RelativePath>[\w\s]+)')
		
		if ($nestedShellMatch.Success)
		{
			$parentShellFolder = (Get-ShellFolder $nestedShellMatch.Groups['ParentShellFolder'].Value).Path
			$librarySimpleLocation = Join-Path $parentShellFolder $nestedShellMatch.Groups['RelativePath'].Value
			
			$librarySimpleLocations += @($LibrarySimpleLocation)
		}
		else
		{		
			# InnerText will actually look something like knownfolder:{4BD8D571-6D19-48D3-BE97-422220080E43}, but Get-KnownFolderPath can automatically extract the guid from that anyway
			$librarySimpleLocation = Get-KnownFolderPath $urlNode.InnerText
			
			$librarySimpleLocations += @($librarySimpleLocation)
		}
	}
	
	return $librarySimpleLocations
}