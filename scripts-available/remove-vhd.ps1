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
 
#It's not working properly - VHDs are mounted as shares.
#Get-ChildItem -Path "$DRIVE\$GARBAGE_DIR" | where { $_.Extension -eq ".txt" -and $_.CreationTime -lt (Get-Date).AddDays($TIMELIMIT) } | ForEach {  
#      Remove-Item $_.FullName
#      Remove-Item $_.DirectoryName+$_.BaseName
#      "Removed file older than $TIMELIMIT days: "+$_.BaseName
#}
