$GARBAGE_DIR = "AUTO.VHD.REMOVE"

$VMID = $(Get-VM).VMId
$DRIVES = $(Get-Volume | Where { $_.DriveLetter -match "[A-Z]" }).DriveLetter
$EXT = ".vsv",".bin"

$DRIVES | ForEach {
$DRIVE = $_+":"

 if( -Not (Test-Path "$DRIVE\$GARBAGE_DIR" -PathType container) ) { 
    "$DRIVE _NOT_ enabled for auto vhd removal $DRIVE\$GARBAGE_DIR directory doesn't exists"
    Return; 
 }

 "$DRIVE enabled for auto vhd removal $DRIVE\$GARBAGE_DIR directory exists"

for ($J=0; $J -lt $EXT.Count; $J++) {
	$ALLFILES = $( Get-ChildItem -Path $DRIVE -Recurse | Where { $_.Attributes -eq 'Archive' -and $_.Extension -Match $EXT[$J] } )
	if( $ALLFILES.Count -gt 0 ) {
		$GARBAGE = $( Compare-Object $ALLFILES.BaseName $VMID ).InputObject
		for ($I=0; $I -lt $GARBAGE.Count; $I++) {
			$(Get-ChildItem $DRIVE -Recurse | Where { $_.Extension -Match $EXT[$J] }).FullName | Where {$_ -Match $GARBAGE[$I] } | Remove-Item | Out-Null
			$EXT[$J]+" file from non-existent VM found! Removed: "+$GARBAGE[$I]+$EXT[$J]
			}
		"`nSummary`n-------"
		"All "+$EXT[$J]+" files found: "+$ALLFILES.Count
		"Unused "+$EXT[$J]+" files found and removed: "+$GARBAGE.Count+"`n"
	}
	else {
		echo "Unused "+$EXT[$J]+" files not found!"
	}
}