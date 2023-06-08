# Script to auto generate a table of contents for Snippets.md

$snippetsText = gc '.\Snippets.md' -Raw

. ..\Add-MDTableOfContent.ps1

Add-MDTableOfContent $snippetsText | Out-File '..\Snippets.md'