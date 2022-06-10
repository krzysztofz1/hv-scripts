#TODO: This script is not working correctly - now all disks are in UNC format.
$DATE_Year = Get-Date -Format yyyy
$DATE_Month = Get-Date -Format MM
$DATE_Full = Get-Date -Format s

$SCRIPTNAME = $MyInvocation.MyCommand.Name
$EVENTNAME = $SCRIPTNAME.Substring(0, $SCRIPTNAME.LastIndexOf('.'))

$LOGDRIVE = "C:"
$LOGPATH = "hv-scripts\logs\$DATE_Year\$DATE_Year-$DATE_Month"
$LOGFILE = $DATE_Full+"-"+$EVENTNAME+".log"

if(!(Test-Path -Path "$LOGDRIVE\$LOGPATH")) {
   New-Item -ItemType Directory -Path "$LOGDRIVE\$LOGPATH"
	}
	
Get-ChildItem "$PSScriptRoot\garbage-collector-enabled" | where { $_.Extension -eq ".ps1" -and $_.Name -notlike "__*" } | foreach { . $_.FullName } > "$LOGDRIVE\$LOGPATH\$LOGFILE"
