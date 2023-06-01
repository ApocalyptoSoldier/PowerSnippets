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