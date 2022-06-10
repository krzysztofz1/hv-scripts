$GARBAGE_DIR = "AUTO.VHD.REMOVE"

$DRIVES = $(Get-Volume | Where { $_.DriveLetter -match "[A-Z]" }).DriveLetter

$TIMELIMIT = -14

$DRIVES | ForEach {
$DRIVE = $_+":"

 if( -Not (Test-Path "$DRIVE\$GARBAGE_DIR" -PathType container) ) { 
    "$DRIVE _NOT_ enabled for auto vhd removal $DRIVE\$GARBAGE_DIR directory doesn't exists"
    Return; 
 }

"$DRIVE enabled for auto vhd removal $DRIVE\$GARBAGE_DIR directory exists"
 
Get-ChildItem -Path "$DRIVE\" | ForEach {  
	foreach($FOLDERS in (Get-ChildItem $DRIVE -Recurse))
		{
			if( ($FOLDERS.PSIsContainer) -and (!(Get-ChildItem -Recurse -Path $FOLDERS.FullName)))
				{
					Remove-Item $FOLDERS.FullName | Out-Null
					"Removed empty folder: "+$FOLDERS.FullName
				}
		}
}
