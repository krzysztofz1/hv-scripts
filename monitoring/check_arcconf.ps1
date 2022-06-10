# Usage: 
# To check AD: .\check_arcconf.ps1 -ModeSelect AD (-AdapterID [ID]) (-CacheTimeOut [min])
# To check LD: .\check_arcconf.ps1 -ModeSelect LD (-AdapterID [ID]) (-LogicalDeviceID [ID]) (-CacheTimeOut [min])
# To check PD: .\check_arcconf.ps1 -ModeSelect PD -SerialNumber [SerialNumber] (-AdapterID [ID]) (-CacheTimeOut [min])
# Nagios configuration generator: .\check_arcconf.ps1 -ModeSelect Nagios (-AdapterID [ID])
# () optional

Param (
	[ValidateNotNullOrEmpty()]
	[alias("MS")]
	[string]$ModeSelect, # Mode select (AD/LD/PD)
	
	[ValidateNotNullOrEmpty()]
	[alias("AID")]
	[int]$AdapterID = 1, # Select Adapter

	[ValidateNotNullOrEmpty()]
	[alias("LDID")]
	[int]$LogicalDeviceID = 0, # Select Logical Device
	
	[ValidateNotNullOrEmpty()]
	[alias("SN")]
	[string]$SerialNumber, # Serial Number for Physical Disks
	
	[ValidateNotNullOrEmpty()]
	[alias("EM")]
	[string]$EmailAddress, # Email Address
	
	[alias("CTO")]
	[int]$CacheTimeOut = 3
)

$ErrorActionPreference = "SilentlyContinue"

$state_ok = 0
$state_warning = 1
$state_critical = 2

$Arcconf = & 'C:\wdc\raidtools\arcconf.exe' getconfig $AdapterID | Out-String
$CacheFile = ".\check_arcconf_AD_$AdapterID.out"
$TimeLimit = (Get-Date).AddMinutes(-$CacheTimeOut)
$Hostname = ($env:ComputerName).ToUpper()
$NotFoundMsg = "ERROR! Controller not found or invalid AdapterID!"

# Parse getconfig output
Function Func-ParseMain {
	Param (
		[int]$Mode
	)

	$MAIN = $CacheFileContent -split "\-+\r?\n.*\r?\n\-+" | select -Skip 1
	$MAIN[$Mode]
}

# Controller information
Function Func-ParseAD {
	$AD = (Func-ParseMain -Mode 0)
	$AD = $AD | %{
	$_ = $_ -replace '\s+:\s+',' = '
	$_ = $_ -replace '\s+\-+.*\r?\n.*\r?\n\s+\-+',''
	$_ = $_ -replace '\s+Command completed successfully.',''
	$_ = ConvertFrom-StringData -StringData $_
	New-Object -TypeName PSObject -Property $_
	}
#$AD | Select 'Controller Status','Defunct disk drive count'
$AD
}

# Logical device information
Function Func-ParseLD {
	$LD = (Func-ParseMain -Mode 1) -split "(?=Logical device number\s\d+)" | select -Skip 1
	$LD = $LD | %{
	$_ = $_ -replace '\s+:\s+',' = '
	$_ = $_ -replace 'Logical device number\s(\d+)','Logical device number = $1'
	$_ = $_ -replace '\s+\-+.*\r?\n.*\r?\n\s+\-+',''
	$_ = $_ -replace '\s+Command completed successfully.',''
	$_ = ConvertFrom-StringData -StringData $_
	New-Object -TypeName PSObject -Property $_
	}
#$LD[$LogicalDeviceID] | Select 'Logical device number','Logical device name','RAID level','Status of logical device'
$LD[$LogicalDeviceID]
}

# Physical Device information
Function Func-ParsePD {
	$PD = (Func-ParseMain -Mode 2) -split "\s+(?=Device #\d+)"
	$PD = $PD | %{
	$_ = $_ -replace '\s+:\s+',' = '
	$_ = $_ -replace 'Device #(\d+)','Device = $1'
	$_ = $_ -replace 'Device is (a|an)\s+(\w+)','DeviceIs = $2'
	$_ = $_ -replace '\s+Status of Enclosure services device(.*\r\n)*',''
	$_ = ConvertFrom-StringData -StringData $_
	New-Object -TypeName PSObject -Property $_
	}
#$PD | select Device,State,'Total size',Model,'Serial number'
$PD
}

if ( Test-Path $CacheFile ) {
		if ( (Get-Item $CacheFile).LastWriteTime -le $TimeLimit ) {
			$Arcconf > $CacheFile
		}
}
else {	
	$Arcconf > $CacheFile
}

$CacheFileContent = Get-Content -Path $CacheFile | Out-String
$LastWrite = (Get-Item $CacheFile).LastWriteTime
$NotExist = ($CacheFileContent | findstr "Invalid controller number.") -contains "Invalid controller number."

switch ($ModeSelect) {
	"AD" {
		$AD_Out = Func-ParseAD
		$AD_Status = $AD_Out.'Controller Status'
		$AD_Model = $AD_Out.'Controller Model'
		if( $AD_Status -eq "Optimal" ) {
			echo "Controller: $AdapterID, Status: $AD_Status, Model: $AD_Model"
			exit $state_ok
			} elseif( $NotExist -eq $true )  {
				echo $NotFoundMsg
				exit $state_critical
			} elseif( $AD_Status -ne "Optimal" )  {
				echo "Controller: $AdapterID, Status: $AD_Status, Controller Model: $AD_Model"
				exit $state_critical
			} else {
				echo "some other error, interesting..."
				exit $state_critical
			}
		break
		}
	"LD" {
		$LD_Out = Func-ParseLD
		$LD_Device = $LD_Out.'Logical device number'
		$LD_RAIDLevel = $LD_Out.'RAID level'
		$LD_Status = $LD_Out.'Status of logical device'
		$LD_Size = [int](($LD_Out.'Size' -replace '^.*?(\d+).*?$','$1')/1024)
		$LD_RCH = $LD_Out.'Read-cache status'
		$LD_WCH = $LD_Out.'Write-cache status'
		if( $LD_Status -eq "Optimal" ) {
			echo "Logical device: $LD_Device, Size: $LD_Size GB, Status: $LD_Status, RAID: $LD_RAIDLevel, RCH: $LD_RCH, WCH: $LD_WCH"
			exit $state_ok
			} elseif( $NotExist -eq $true )  {
				echo $NotFoundMsg
				exit $state_critical
			} elseif( $LD_Status -ne "Optimal" )  {
				echo "Logical device: $LD_Device, Size: $LD_Size GB, Status: $LD_Status, RAID: $LD_RAIDLevel, RCH: $LD_RCH, WCH: $LD_WCH"
				exit $state_critical
			} else {
				echo "some other error, interesting..."
				exit $state_critical
			}
		break
		}
	"PD" {
		$PD_Out = Func-ParsePD  | ? { $_."Serial number" -eq $SerialNumber }
		$PD_Count = ($PD_Out | Measure).Count
		$PD_State = $PD_Out.'State'
		$PD_Size = [int](($PD_Out.'Total Size' -replace '^.*?(\d+).*?$','$1')/1024)
		$PD_Vendor = $PD_Out.'Vendor'		
		$PD_Model = $PD_Out.'Model'
			if( $PD_Count -eq 1 -And $PD_State -eq "Online" ) {
			echo "SerialNumber: $SerialNumber, State: $PD_State, Size: $PD_Size GB, Model: $PD_Vendor $PD_Model"
			exit $state_ok
			} elseif( $NotExist -eq $true )  {
				echo $NotFoundMsg
				exit $state_critical
			} elseif( $PD_Count -eq 1 -And $PD_State -ne "Online" ) {
				echo "SerialNumber: $SerialNumber, State: $PD_State, Size: $PD_Size GB, Model: $PD_Vendor $PD_Model"
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
	"Nagios" {

		$AD_Out = Func-ParseAD
		$LD_Out = Func-ParseLD
		$PD_Out = Func-ParsePD

#AD
		if( $NotExist -eq $false ) {

			ForEach( $AD_ in $AD_Out ) {
	
			$AD_Model = $AD_.'Controller Model'
			
			$NagiosCfg += @"
define service {
        host_name               wdc - $Hostname
        max_check_attempts      3
        service_description     $AD_Model Controller $AdapterID Status - NRPE
        check_command           check_nrpe!-c check_arcconf_ad -a $AdapterID
        contact_groups          admins
        check_period            24x7
}

"@

			}



# LD

			ForEach( $LD_ in $LD_Out ) {

				$AD_Model = $AD_Out.'Controller Model'
				$LD_Device = $LD_.'Logical device number'
				$LD_Size = [int](($LD_.'Size' -replace '^.*?(\d+).*?$','$1')/1024)
				$LD_RAIDLevel = $LD_.'RAID level'

				$NagiosCfg += @"
define service {
        host_name               wdc - $Hostname
        max_check_attempts      3
        service_description     $AD_Model Logical Device $LD_Device Status - $LD_Size GB - RAID $LD_RAIDLevel Volume - NRPE
        check_command           check_nrpe!-c check_arcconf_ld -a $AdapterID $LD_Device
        contact_groups          admins
        check_period            24x7
}

"@

			}

# PD

			ForEach( $PD_ in $PD_Out ) {
	
				$AD_Model = $AD_Out.'Controller Model'
				$PD_Serial = $PD_.'Serial number'
				$PD_Size = [int](($PD_.'Total Size' -replace '^.*?(\d+).*?$','$1')/1024)
				$PD_Vendor = $PD_.'Vendor'
				$PD_Model = $PD_.'Model'

				if ( $PD_Size -gt 0 ) {
					
					$NagiosCfg += @"
define service {
        host_name               wdc - $Hostname
        max_check_attempts      3
        service_description     $AD_Model PhysicalDisk - SN: $PD_Serial - $PD_Size GB - $PD_Vendor $PD_Model - NRPE
        check_command           check_nrpe!-c check_arcconf_pd -a $AdapterID $PD_Serial
        contact_groups          admins
        check_period            24x7
}

"@
				}
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
