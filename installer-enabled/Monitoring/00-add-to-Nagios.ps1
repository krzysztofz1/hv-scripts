Param(

	[string]$HostName = (Get-WmiObject win32_computersystem).DNSHostName+"."+(Get-WmiObject win32_computersystem).Domain

)


try {
  Write-Host -ForegroundColor Green "Adding nagios monitoring for $($HostName)..."
  Invoke-RestMethod -Method Post -Uri "http://api.nagios.wdc.pl:8080/vmhost/$($HostName)?x-auth-token=hdfrrvvslgSFDf230xdfgh34"  -ContentType "application/json" -ErrorAction:Stop
}
catch {
  
    Write-Host -ForegroundColor Red "Could not add nagios monitoring..."
    $Error[0]

}

