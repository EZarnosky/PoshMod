function Test-ezIsValidDate {
    [CmdletBinding()]Param(
		[Parameter(Mandatory=$TRUE)]$Date
	)

	(($Date -AS [DateTime]) -NE $NULL)
} 
