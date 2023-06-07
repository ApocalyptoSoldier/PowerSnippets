Resolve a path so it looks exactly like windows would show it, including slashes and case

```PowerShell
$path = (Get-Item HKCU:\Software\Valve\Steam\).GetValue("SteamPath") # looks like "c:/program files (x86)/steam"
$path | Resolve-Path # looks like "C:\program files (x86)\steam" which is better
$path | Get-Item | Select -ExpandProperty FullName # looks like "C:\Program Files (x86)\Steam", correct case and everything
```


Get the path to a windows special folder
```PowerShell
[Environment]::GetFolderPath('MyDocuments')
```

See ``Get-SpecialFolder`` for an example



Get the path to a shell folder, eg. shell:Startup or shell:Downloads
The simple way
```PowerShell
(New-Object -ComObject Shell.Application).Namespace('shell:Startup').Self.Path
```
The more complex and reliable way involves calling the [SHGetKnownFolderPath](https://learn.microsoft.com/en-us/windows/win32/api/shlobj_core/nf-shlobj_core-shgetknownfolderpath) api
See ``Get-ShellFolder`` for an example.


Faster way to get folder size
Recursing through all files in a folder and adding up their individual sizes can be quite slow.
Using the [Scripting.FileSystemObject](https://learn.microsoft.com/en-us/office/vba/language/reference/user-interface-help/filesystemobject-object) com object can be much faster
```PowerShell
$fso = New-Object -ComObject Scripting.FileSystemObject
$fso.GetFolder("$($env:USERPROFILE)\Downloads").Size
```