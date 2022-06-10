Param(
	[Parameter(Position=1)]
	[string]$FriendlyName
	
)

TRY {
	$ErrorActionPreference = "Stop"

	if( $FriendlyName ) {
		$VD = $(Get-VirtualDisk -FriendlyName $FriendlyName)
	} else {
		$VD = $(Get-VirtualDisk)[0]
	}

} CATCH {	
	echo $ERROR[0].exception.message
	exit 2
}

$OpStatus = $VD.OperationalStatus
$Health = $VD.HealthStatus
$Name = $VD.FriendlyName

if( $VD.OperationalStatus -eq "OK" -and $VD.HealthStatus -eq "Healthy" ) {
	echo "StorageSpaces: $Name, OpStatus: $OpStatus, Health: $Health"
	exit 0
} else {
	echo "StorageSpaces: $Name, OpStatus: $OpStatus, Health: $Health"
	exit 2
}