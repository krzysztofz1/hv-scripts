$GARBAGE_DIR = "AUTO.VHD.REMOVE"

$HDS = $(Get-VM).HardDrives
$DRIVES = $(Get-Volume | Where { $_.DriveLetter -match "[A-Z]" }).DriveLetter

$DRIVES | ForEach {
$DRIVE = $_+":"

 if( -Not (Test-Path "$DRIVE\$GARBAGE_DIR" -PathType container) ) { 
    "$DRIVE _NOT_ enabled for auto vhd removal $DRIVE\$GARBAGE_DIR directory doesn't exists"
    Return; 
 }

 "$DRIVE enabled for auto vhd removal $DRIVE\$GARBAGE_DIR directory exists"

 $VHDS = $( Get-ChildItem -Path $DRIVE -Recurse | Where { $_.Attributes -eq 'Archive' -and $_.Extension -match ".vhd?" } )
 
 if( $VHDS.length -gt 0 ) {
  $GARBAGE = $( ( Compare-Object $HDS.Path $VHDS.FullName ).InputObject | Get-Item )
  if( $GARBAGE.length -gt 0 ) {
	$GARBAGE | ForEach {
		$DST = "$DRIVE\$GARBAGE_DIR\"+($_.Name)+"_"+$TIME
		$DST_TXT = $DST+".txt"
		Move-Item -Path $_.FullName -Destination $DST
		"" > $DST_TXT
        }
	$GARBAGE | Format-List FullName,Length,LastWriteTime
  }
 }
}
