Param(

	[string]$HostName = $env:ComputerName

)

$hArray = $HostName.Split('-') 

$Retrymax = 5
$Retrycount = $Retrymax

Function Func-AddToADGroup {

	Param(
		
		[string]$ADComputerName,
		[string]$Domain,
		[string]$GroupName
		
	)
	
	$Stoploop = $false
	
	do {
		try {
			Write-Host -ForegroundColor Green "Adding computer to group in AD..."
			Invoke-Command -ComputerName $ADComputerName -Credential $(Get-Credential -Username Administrator@$Domain -message "Enter Administrator password") -ScriptBlock { param($HostName,$GroupName) Add-ADGroupMember -Identity $GroupName -Members "$Hostname$"; Write-Host -ForegroundColor Green "Success" } -ArgumentList $HostName,$GroupName -ErrorAction Stop
			$Stoploop = $true
		}
		catch {
			if ($Retrycount -eq 0) {
			
				Write-Host -ForegroundColor Red "Could not add to AD group after $Retrymax attempts..."
				$Stoploop = $true
			
				} else {
					
					$Retrycount = $Retrycount - 1
					Write-Host -ForegroundColor Red "Something went wrong... try again... [$Retrycount attempts left]"
					$Error[0]
					
				}
		}
	}

While ($Stoploop -eq $false)
}		


Func-AddToADGroup -ADComputerName wdc-ad-30 -Domain rbx.wdc.pl -GroupName "RBX Servers"
