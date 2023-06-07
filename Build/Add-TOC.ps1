# Script to auto generate a table of contents for Snippets.md

$snippetsText = gc '.\Snippets.md' -Raw

$snippetsMD = $snippetsText | ConvertFrom-Markdown

$headings = $snippetsMD.Tokens | ? { $_ -is 'Markdig.Syntax.HeadingBlock' }

$toc = '# Table of Content'
$toc += "`r"

$newSnippetsText = ''

foreach ($heading in $headings)
{
	$headerText = $heading.Inline.Content.ToString()
	$headerLink = [Markdig.Helpers.LinkHelper]::UrilizeAsGfm($headerText)

	$toc += "+ [$headerText](#$headerLink)`r"
}

($toc + "`r`r" + $snippetsText) | Out-File ..\Snippets.md