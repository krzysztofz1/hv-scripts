Write-Host -ForegroundColor Green "Clean network settings... wait 20 sec..."

$NetAdapter = Get-NetAdapter -Physical

Set-DnsClientServerAddress -InterfaceIndex $NetAdapter.ifIndex -ResetServerAddresses

Get-NetRoute | Where { $_.NextHop -eq "169.254.0.1" } | Remove-NetRoute -Confirm:$false

Start-Sleep -s 20