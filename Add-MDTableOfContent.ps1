<#
.Synopsis
	Generates a table of content for the given markdown formatted string
	Requires PowerShell Core
.Example
	PS> Add-MDTableOfContent @"
	# Heading 1
	## Subheading 1
	Some content
	## Subheading 2
	Some content
	# Heading 2
	# Subheading 2
	Some content
	"@
	
	# Table of Content
	+ [Heading 1](#heading-1)
			+ [Subheading 1](#subheading-1)
			+ [Subheading 2](#subheading-2)
	+ [Heading 2](#heading-2)
	+ [Subheading 2](#subheading-2-1)

	# Heading 1
	## Subheading 1
	Some content
	## Subheading 2
	Some content
	# Heading 2
	# Subheading 2
	Some content
#>
function Add-MDTableOfContent()
{
	param([string]$MarkdownString)
	
	$MarkdownContent = $MarkdownString | ConvertFrom-Markdown | Select -ExpandProperty Tokens
	$headings = $MarkdownContent | Where { $_ -is 'Markdig.Syntax.HeadingBlock' }
	
	$toc = '# Table of Content'
	$toc += "`n"
	
	foreach ($heading in $headings)
	{
		$headerText = $heading.Inline.Content.ToString()
		$headerID = [Markdig.Renderers.html.HtmlAttributesExtensions]::GetAttributes($heading).Id
		$indent = $heading.Level - 1
		$toc += ("`t" * $indent)
		$toc += "+ [$headerText](#$headerID)`n"
	}
	
	return "$toc`n$MarkdownString"
}