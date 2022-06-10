Param(
	[Parameter(Position=1)]
	[string[]] $SerialNumber = "*"

)

$ScriptLocation = split-path -parent $MyInvocation.MyCommand.Definition
$CacheFile = $ScriptLocation + "\check_physicaldisks.out"

If (Test-Path $CacheFile) { 

  $CacheFileItem = Get-ChildItem $CacheFile

  if ( $CacheFileItem.LastWriteTime -le (Get-Date).AddHours(-3) ){
    echo $CacheFileItem.LastWriteTime
    echo (Get-Date).AddHours(-3)
    echo "PhysicalDisk Serial Number Cache file older than 3 hours."
    exit 2
  }
}else{
  Get-PhysicalDisk -ErrorAction "Stop"| Export-CliXML -Path $CacheFile
}

$CACHE = Import-CliXML $CacheFile 

Filter SelectSN($patterns) { 
  $obj = $_; 
  foreach($p in $patterns) { 
    if($obj.serialnumber.trim() -like $p) { 
      return $obj; 
     } 
  } 
}

$SN = $CACHE | SelectSN $SerialNumber  

TRY {
	$ErrorActionPreference = "Stop"
	$PDALL = Get-PhysicalDisk -ErrorAction "Stop";
	$PD = @()
	$PD += $PDALL | Where { $_.SerialNumber.trim() -in $SN.SerialNumber.trim() }

} CATCH {
	echo $_.exception.message
	exit 2
}

if( $PD.length -lt $SN.length ) {
    echo "No disk found for serial number: $($SerialNumber -join ",")"
    exit 2
 }

$CRITICAL = @()

$PD | ForEach {
	if( $_.OperationalStatus -eq "OK" -and  $_.HealthStatus -eq "Healthy" ) { 
#		$SN.Remove(([string]$_.SerialNumber).trim());
    $CurrentSN = $_.SerialNumber.trim();
    $SN = $SN | Where { $_.SerialNumber.trim() -ne $CurrentSN } 
	}
	else { 
		$CRITICAL += $_ 
	}
}

if( $CRITICAL.length -gt 0 ) {

 
  $OUTPUT = @();
  $SN | ForEach {
    $OUTPUT += "SN: $($_.SerialNumber), $($_.Size/1GB) GB, $($_.Model)"
  }

	echo "PhysicalDisk failed: $($OUTPUT -join " | ")";
	exit 2;
}
else {
#  [string]$PDALL.SerialNumber.trim() | Out-File $CacheFile ;
  $PDALL | Export-CliXML -Path $CacheFile

  if( $PD.Length -eq 1) {
    
    echo "SN: $($PD.SerialNumber), $($PD.Size/1GB) GB, $($PD.Model)"
  }else{
    echo "All PhyscialDisk: OK, number of disks: $($PDALL.length)"
  }
	exit 0;
}
