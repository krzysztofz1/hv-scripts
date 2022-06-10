Param(
  [Parameter(Position=1)]
  [string[]]$FriendlyName = "*"
)

TRY {
        $ErrorActionPreference = "Stop"

        $VD = Get-VirtualDisk -FriendlyName $FriendlyName -ErrorAction STOP

} CATCH {
        echo $ERROR[0].exception.message
        exit 2
}

$CRITICAL = @();

$VD | ForEach {
  if( $_.OperationalStatus -ne "OK" -and $_.HealthStatus -ne "Healthy" ) {
    $CRITICAL += $_;
  }
}

if( $CRITICAL.length -gt 0 ) {
  $OUTPUT = @();
  $CRITICAL | ForEach {
    $OUTPUT += "VirtualDisk: $($_.FriendlyName), OpStatus: $($_.OperationalStatus), Health: $($_.HealthStatus)"
  };
  echo $( $OUTPUT -join " | ");
  exit 2;
}
else {
  echo "All Virtual disks: OK [$($VD.FriendlyName -join ",")]"
  exit 0;
}