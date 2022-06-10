$RegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\TrapConfiguration"

if( !(Test-Path -Path $RegPath) ) {
	New-Item -Path HKLM:\SYSTEM\CurrentControlSet\Services\SNMP\Parameters\ -Name TrapConfiguration
}
