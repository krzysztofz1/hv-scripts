$NetAdapter = @();

$NetAdapter += Get-NetAdapter -Physical | Where { $_.status -eq "Up" }

while( $NetAdapter.length -lt 1 ) {
	$NetAdapter = Get-NetAdapter -Physical | Where { $_.status -eq "Up" }
	Write-Host
	Write-Host -ForegroundColor Red "There are not physical Network Interfaces connected to switch !"
	Write-Host
	Read-Host "Connect physical Network Interfaces to switch and press ENTER"
}

$ifIndex = $NetAdapter[0].ifIndex

New-NetRoute -InterfaceIndex $ifIndex -NextHop 169.254.0.1 -DestinationPrefix 0.0.0.0/0

Set-DnsClientServerAddress -InterfaceIndex $ifIndex -ServerAddresses @("8.8.8.8","8.8.4.4")

Write-Host -ForegroundColor Green "Configuring network... wait 45 sec..."
Start-Sleep -s 45
