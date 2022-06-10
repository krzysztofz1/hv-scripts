Param(
	[string]$ComputerName = (Read-Host "Hostname")

)

Write-Host -ForegroundColor Green "Trying to change computer name to: $ComputerName"

Rename-Computer -NewName $ComputerName
