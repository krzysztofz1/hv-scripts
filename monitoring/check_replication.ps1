Param(
	[string]$VMName
)

TRY {
	$ErrorActionPreference = "Stop"

	if( $VMName ) {
		$Rep = $(Get-VMReplication -VMName $VMName)
	} else {
		echo "Provide VM name"
        exit 2
	}

} CATCH {	
	echo $ERROR[0].exception.message
	exit 2
}

$State = $Rep.State
$Health = $Rep.Health
$Name = $Rep.Name

if( $Rep.State -eq "Replicating" -and $Rep.Health -eq "Normal" ) {
	echo "Replication: $Name, Status: OK, Health: OK"
	exit 0
} else {
	echo "Replication: $Name, Status: $State, Health: $Health"
	exit 2
}