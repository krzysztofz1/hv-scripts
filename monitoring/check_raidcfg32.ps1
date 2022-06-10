# Usage: 
# To check PD: .\check_arcconf.ps1 -ModeSelect PD -SerialNumber [SerialNumber] (-CacheTimeOut [min])
# To check LD: .\check_arcconf.ps1 -ModeSelect LD (-LogicalDeviceID [ID]) (-CacheTimeOut [min])
# Nagios configuration generator: .\check_arcconf.ps1 -ModeSelect Nagios
# () optional

Param (
	[ValidateNotNullOrEmpty()]
	[alias("MS")]
	[string]$ModeSelect, # Mode select (PD/LD)

	[ValidateNotNullOrEmpty()]
	[alias("LDID")]
	[int]$LogicalDeviceID = 0, # Select Logical Device
	
	[ValidateNotNullOrEmpty()]
	[alias("SN")]
	[string]$SerialNumber, # Serial Number for Physical Disks
	
	[alias("CTO")]
	[int]$CacheTimeOut = 3
)

$ErrorActionPreference = "SilentlyContinue"

$state_ok = 0
$state_warning = 1
$state_critical = 2

$RaidCfg32 = & 'C:\wdc\raidtools\RAIDCFG32.exe' /I | Out-String
$CacheFile = ".\check_raidcfg32.out"
$TimeLimit = (Get-Date).AddMinutes(-$CacheTimeOut)
$Hostname = ($env:ComputerName).ToUpper()
$NotFoundMsg = "ERROR! Controller not found!"

# Parse RaidCfg32 output
Function Func-ParseMain {
	$MAIN = $CacheFileContent -replace '\s*:\s*',':' -split "(?=RAID\s)" | select -skip 1
	$MAIN = $MAIN -replace '\r?\n-+\r?\n.*?\r?\n\r?\n',''
	$MAIN
}

# Physical Device information
Function Func-ParsePD {
	$PD = $(Func-ParseMain)[0] -replace '(?=\n)\s\t+.*','' -split '(?=\sDrive:)' | select -skip 1
	$PD = $PD | %{
	$_ = $_ -replace '\s?\t+',"`r`n " -replace ':','='
	$_ = ConvertFrom-StringData -StringData $_
	New-Object -TypeName PSObject -Property $_
	}
$PD
}

# Logical Device information
Function Func-ParseLD {
	$LD = $(Func-ParseMain)[1] -split '(?=Volume \d / \d)' | select -skip 1
	$LD = $LD | %{
	$_ = $_ -replace 'Volume\s+(\d+\s/\s\d+)','Volume = $1' -replace '\s?\t+',"`r`n " -replace ':','='
	$_ = ConvertFrom-StringData -StringData $_
	New-Object -TypeName PSObject -Property $_
	}
$LD[$LogicalDeviceID]
}

if ( Test-Path $CacheFile ) {
		if ( (Get-Item $CacheFile).LastWriteTime -le $TimeLimit ) {
			$RaidCfg32 > $CacheFile
		}
}
else {	
	$RaidCfg32 > $CacheFile
}

$CacheFileContent = Get-Content -Path $CacheFile | Out-String
$LastWrite = (Get-Item $CacheFile).LastWriteTime
$NotExist = ($CacheFileContent | findstr "OROM   Version: 0.0.0.0") -contains "OROM   Version: 0.0.0.0"

switch ($ModeSelect) {
	"PD" {
		$PD_Out = Func-ParsePD  | ? { $_."SerialNo" -eq $SerialNumber }
		$PD_Count = ($PD_Out | Measure).Count
		$PD_CfgStatus = $PD_Out.'CfgStatus'
		$PD_Drive = $PD_Out.'Drive'
		$PD_Summary = $PD_Out.'Summary'
		$PD_WCH = $PD_Out.'WriteCache'
		if( $PD_Count -eq 1 -And $PD_CfgStatus -eq "(0) Ok" ) {
			echo "SerialNumber: $SerialNumber, Status: $PD_CfgStatus, Summary: $PD_Summary, Model: $PD_Drive, WCH: $PD_WCH"
			exit $state_ok
			} elseif( $NotExist -eq $true )  {
				echo $NotFoundMsg
				exit $state_critical
			} elseif( $PD_Count -eq 1 -And $PD_CfgStatus -ne "(0) Ok"  ) {
				echo "SerialNumber: $SerialNumber, Status: $PD_CfgStatus, Summary: $PD_Summary, Model: $PD_Drive, WCH: $PD_WCH"
				exit $state_critical
			} elseif( $PD_Count -eq 0 ) {
				echo "disk with serial $SerialNumber not found, defective?"
				exit $state_critical
			} elseif( $PD_Count -gt 1 )  {
				echo "do you have right serial number? too many disks found: $PD_Count"
				exit $state_critical
			} else {
				echo "some other error, interesting..."
				exit $state_critical
			}
		break
		}
	"LD" {
		$LD_Out = Func-ParseLD
		$LD_SerialNo = $LD_Out.'SerialNo'
		$LD_Size = [int](($LD_Out.'SizeInMB')/1024)
		$LD_CfgStatus = $LD_Out.'CfgStatus'
		$LD_Summary = $LD_Out.'Summary'
		$LD_RaidLevel = $LD_Out.'RaidLevel'
		if( $LD_Summary -eq "Normal" ) {
			echo "Logical device: $LD_SerialNo, Size: $LD_Size GB, Status: $LD_CfgStatus, Summary: $LD_Summary, RAID: $LD_RaidLevel"
			exit $state_ok
			} elseif( $NotExist -eq $true )  {
				echo $NotFoundMsg
				exit $state_critical
			} elseif( $LD_Summary -eq "Degraded" )  {
				echo "Logical device: $LD_SerialNo, Size: $LD_Size GB, Status: $LD_CfgStatus, Summary: $LD_Summary, RAID: $LD_RaidLevel"
				exit $state_critical
			} elseif( $LD_Summary -Match "Rebuild=*" )  {
				echo "Logical device: $LD_SerialNo, Size: $LD_Size GB, Status: $LD_CfgStatus, Summary: $LD_Summary, RAID: $LD_RaidLevel"
				exit $state_warning
			} else {
				echo "some other error, interesting... summary: $LD_Summary"
				exit $state_critical
			}
		break
		}
	"Nagios" {

		$LD_Out = Func-ParseLD
		$PD_Out = Func-ParsePD

# PD
		if( $NotExist -eq $false ) {

			ForEach( $PD_ in $PD_Out ) {
	
				$PD_Drive = $PD_.'Drive'
				$PD_Serial = $PD_.'SerialNo'
					
				$NagiosCfg += @"
define service {
        host_name               wdc - $Hostname
        max_check_attempts      3
        service_description     Intel Matrix PhysicalDisk - SN: $PD_Serial - $PD_Drive - NRPE
        check_command           check_nrpe!-c check_raidcfg32_pd -a $PD_Serial
        contact_groups          admins
        check_period            24x7
}

"@
			}
			
# LD

			ForEach( $LD_ in $LD_Out ) {

				$LD_Volume = $LD_.'Volume'
				$LD_Size = [int](($LD_.'SizeInMB')/1024)
				$LD_RaidLevel = $LD_.'RaidLevel'

				$NagiosCfg += @"
define service {
        host_name               wdc - $Hostname
        max_check_attempts      3
        service_description     Intel Matrix Logical Volume $LD_Volume - $LD_Size GB - RAID $LD_RaidLevel Volume - NRPE
        check_command           check_nrpe!-c check_raidcfg32_ld -a $LD_Volume
        contact_groups          admins
        check_period            24x7
}

"@

			}

		} else {

		echo $NotFoundMsg

		}

	echo $NagiosCfg

	if( $EmailAddress ) {
	echo "Sending mail message with Nagios config to: $EmailAddress"
	send-mailmessage -SmtpServer "mx0.rubikon.pl" -to "$EmailAddress" -from "$Hostnmae <mail@$Hostname.wdc.pl>" -subject "Konfiguracja Nagios $Hostname - dyski i macierze" -Body "$NagiosCfg"	
	}
	break
	}		
}
