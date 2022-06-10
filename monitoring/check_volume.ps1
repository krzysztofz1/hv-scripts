Param(
	[Parameter(Position=1)]
	[string[]] $DriveLetter = "*",
	
	[Parameter(Position=2)]
	[int] $WarningThresh = 80,
	
	[Parameter(Position=3)]
	[int] $CriticalThresh = 90
	
)
function OUTPUT($DATA){
  $OUT = @();
  $DATA | ForEach {
    $UsedSpace =  [int](100*($_.Size - $_.SizeRemaining)/$_.Size);
    $OUT += "Volume: $($_.DriveLetter), Health: $($_.HealthStatus), UsedSpace: $($UsedSpace)%, Size: $($_.Size/1GB) GB, SizeRemaining: $($_.SizeRemaining/1GB) GB ";   
  }
  
  return $( $OUT -join " | ")
}

$ScriptLocation = split-path -parent $MyInvocation.MyCommand.Definition
$CustomThreshFile = $ScriptLocation + "\check_volume_custom_thresh.json"

If (Test-Path $CustomThreshFile) { 

  $CustomThresh = $( Get-Content -Raw -Path $CustomThreshFile | ConvertFrom-Json).CustomThresh

}


TRY {
	$ErrorActionPreference = "Stop"

	$VD = $(Get-Volume | Where { $_.DriveLetter -match "^\w$" } | where { $_.DriveLetter -like $DriveLetter } )

} CATCH {	
	echo $ERROR[0].exception.message
	exit 2
}

if( $VD.length -eq 0 ){
  echo "No volume found: $($DriveLetter)"
exit 3
}

$CRITICAL = @();
$WARNING = @();


$VD | ForEach {
  $UsedSpace =  [int](100*($_.Size - $_.SizeRemaining)/$_.Size);
  $CurrentVolume = $_;
  $CurrentThresh =$($CustomThresh| where {$_.DriveLetter -eq $CurrentVolume.DriveLetter})
  $CurrentThreshCritical = ( @( $CurrentThresh.CriticalThresh , $CriticalThresh) | Where { $_ -match "^\d+$" } )[0];
  $CurrentThreshWarning = ( @( $CurrentThresh.WarningThresh , $WarningThresh) | Where { $_ -match "^\d+$" } )[0];

  if( $_.HealthStatus -ne "Healthy" ){
    $CRITICAL += $_;
  } elseif( $UsedSpace -ge $CurrentThreshCritical){
     $CRITICAL += $_;
  } elseif($UsedSpace -ge $CurrentThreshWarning ) {
    $WARNING +=  $_;
  }

}
if( $CRITICAL.length -gt 0 ) {
  echo $(OUTPUT($CRITICAL))
  exit 2;
} elseif( $WARNING.length -gt 0 ){
   echo $(OUTPUT($WARNING))
  exit 1;
}else {  
  echo "All volume: OK [$($VD.DriveLetter -join ",")]"
  exit 0;
}

