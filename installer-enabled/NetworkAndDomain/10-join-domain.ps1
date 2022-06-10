Param(

	[string]$HostName = $env:ComputerName

)

$hArray = $HostName.Split('-') 

$Retrymax = 5
$Retrycount = $Retrymax

Function Func-JoinDomain {

	Param(
		
		[string]$Domain
		
	)
	
	$Stoploop = $false
	
	do {
		try {
			Write-Host -ForegroundColor Green "Joining domain"
			Add-Computer -DomainName $Domain.ToUpper() -Credential $(Get-Credential -Username Administrator@$Domain -message "Enter Administrator password") -ErrorAction Stop
			Write-Host -ForegroundColor Green "Success"
			$Stoploop = $true
		}
		catch {
			if ($Retrycount -eq 0) {
			
				Write-Host -ForegroundColor Red "Could not join domain after $Retrymax attempts..."
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


Func-JoinDomain -Domain rbx.wdc.pl
