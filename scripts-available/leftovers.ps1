Param(
	[string]$EmailAddress = "raporty@wdc.pl"
)

$GARBAGE_DIR = "AUTO.VHD.REMOVE"

$DRIVES = $(Get-Volume | Where { $_.DriveLetter -match "[A-Z]" }).DriveLetter

$HOSTNAME = $env:ComputerName
$EXCLUDE = '*.vsv','*.bin','*.vhd?','*.vhd??*','AUTO.VHD.REMOVE\*'

$DRIVES | ForEach {
$DRIVE = $_+":"

 if( -Not (Test-Path "$DRIVE\$GARBAGE_DIR" -PathType container) ) { 
    "$DRIVE _NOT_ enabled for auto vhd removal $DRIVE\$GARBAGE_DIR directory doesn't exists"
    Return; 
 }

"$DRIVE enabled for auto vhd removal $DRIVE\$GARBAGE_DIR directory exists"

Get-ChildItem $DRIVE -Recurse -Exclude $EXCLUDE | Where { ! $_.PSIsContainer } | ForEach {
	"Unknown file found: $_"
	$BODY += "Unknown file found: $_`n"
}

if ( $BODY -ne $NULL ) {
	echo "`nSending unknown files report to: $EMAILADDRESS"
	Send-MailMessage -SmtpServer "mx0.rubikon.pl" -to "$EMAILADDRESS" -from "$HOSTNAME <mail@$Hostname.wdc.pl>" -subject "Unknown files report from server $HOSTNAME" -Body "$BODY"	
}
else {
	echo "Unknown files not found!"
}
