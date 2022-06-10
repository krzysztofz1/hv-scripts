$GARBAGE_DIR = "AUTO.VHD.REMOVE"

$DRIVES = $(Get-Volume | Where { $_.DriveLetter -match "[A-Z]" }).DriveLetter

$DRIVES | ForEach {
$DRIVE = $_+":"

 if( -Not (Test-Path "$DRIVE\$GARBAGE_DIR" -PathType container) ) { 
    "$GARBAGE_DIR directory doesn't exists: script not run for $DRIVE"
    Return; 
 }

"$DRIVE\$GARBAGE_DIR directory exists: looking for VHD(X) files to move"
 
Get-VMHardDiskDrive * | where { $_.Path -like "$DRIVE\*\*" } | ForEach {
	Move-VMStorage $_.VMName -DestinationStoragePath $DRIVE
	"VHD(X) file moved to $DRIVE root: $_.Path"
}
