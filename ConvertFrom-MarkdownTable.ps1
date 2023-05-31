<#
.Synopsis 
	Converts a markdown formatted table to PSObject type objects
	
.Parameter MarkdownString
	The markdown string representing the table
	
.Example
	PS> @"
	| side | length |
	|------|--------|
	| a    | 3      |
	| b    | 4      |
	| c    | 5      |
	@" | ConvertFrom-MarkdownTable

	side length
	---- ------
	a    3
	b    4
	c    5
#>
function ConvertFrom-MarkdownTable(){
	param(
		[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$MarkdownString
	)
	
	# Trim any extra whitespace, except newlines, around pipe characters
	$MarkdownString = $MarkdownString -replace '[\t ]*\|[\t ]*', '|'
	
	# Replace the pipes at the start and end of each line
	$MarkdownString = $MarkdownString -replace "(?m)^\|", '' -replace "(?m)\|$", ''
	
	$tableData = $MarkdownString | ConvertFrom-Csv -Delimiter '|'
	
	# The first line is just dashes
	return $tableData | Select-Object -Skip 1
}