Param(
	[bool]$StorageSpaces = $True,
	[bool]$Disks = $True,
	[string]$EmailAddress
)


# $Hostname = [system.net.dns]::gethostbyname(($env:computername)).Hostname
$Hostname = $env:ComputerName
$Hostname = $Hostname.ToUpper()

if( $StorageSpaces -eq $True ) {

	$SSS = $(Get-VirtualDisk)

	ForEach( $SS in $SSS ) {

		$FriendlyName = $SS.FriendlyName
		$Size = [math]::round($SS.Size / 1Gb, 0)

$NagiosCfg += @"
define service {
	host_name               wdc - $Hostname
        max_check_attempts      3
        service_description     StorageSpaces $FriendlyName - array state - $Size GB - NRPE
        check_command           check_nrpe!-c check_storagespaces -a $FriendlyName
        contact_groups          admins
        check_period            24x7
}

"@

	}

}


if( $Disks -eq $True ) {

	$PDS = $(Get-PhysicalDisk)

	ForEach( $PD in $PDS ) {

		$SerialNumber = ([string]$PD.SerialNumber).trim()
		$Size = [math]::round($PD.Size / 1Gb, 0)
		$Model = $PD.Model

$NagiosCfg += @"
define service {
	host_name               wdc - $Hostname
	max_check_attempts      3
	service_description     PhysicalDisk - SN: $SerialNumber - $Size GB - $Model - NRPE
	check_command           check_nrpe!-c check_physicaldisk -a $SerialNumber
	contact_groups          admins
	check_period            24x7
}

"@

	}

}

echo $NagiosCfg

if( $EmailAddress ) {
	echo "sending mail message with Nagios config to: $EmailAddress"
	send-mailmessage -SmtpServer "mx0.rubikon.pl" -to "$EmailAddress" -from "$Hostnmae <mail@$Hostname.wdc.pl>" -subject "Konfiguracja Nagios $Hostname - dyski i macierze" -Body "$NagiosCfg"	
}
