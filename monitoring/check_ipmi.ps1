# Usage: 
# To check PD: .\check_ipmi.ps1 -SensorName [SensorName] -Warning [range: x,y] -Critical [range: x,y] (-CacheTimeOut [min])
# () optional

Param (

	[ValidateNotNullOrEmpty()]
	[alias("Name")]
	[string]$SensorName,

	[ValidateCount(2, 2)]
	[alias("W")]
	[string[]]$Warning,

	[ValidateCount(2, 2)]	
	[alias("C")]
	[string[]]$Critical,
		
	[alias("CTO")]
	[int]$CacheTimeOut = 3
	
)

$ErrorActionPreference = "SilentlyContinue"
$ScriptLocation = split-path -parent $MyInvocation.MyCommand.Definition
$IPMIcfgLocation = 'C:\wdc\ipmicfg-win\'

$WarningLine = ($Warning | measure-object -maximum).maximum
$CriticalLine = ($Critical | measure-object -maximum).maximum

$NotFoundMsg = "ERROR! IPMI module not found!"
$IPMIcfgCrashMsg = "ipmicfg-win crashed. it will be killed now..."
$NeedResetMsg = "IPMI module crashed! Probably needs a reset! (ipmicfg-win -r)"

$State = @{ 
	"Ok" = 0
	"Warning" = 1
	"Critical" = 2
}

if ( [bool](Get-Process -Name ipmicfg-win -ErrorAction SilentlyContinue) -eq $true ) {

	Get-Process -Name ipmicfg-win | Stop-Process -Force
	$IPMIcfgCrashMsg
	exit $State.Warning
	
}

Set-Location $IPMIcfgLocation
$IPMI = (.\ipmicfg-win.exe -sdr  | Out-String) -split "\r?\n";
$CacheFile = $ScriptLocation + "\check_ipmi.out"
$TimeLimit = (Get-Date).AddMinutes(-$CacheTimeOut)

# Parse IPMIcfg-win output
Function Func-ParseMain {
	$MAIN = $CacheFileContent -split "\r?\n";
	$MAIN = $MAIN | Select -Skip 2 | where { $_ -match "\|" };
	$MAIN = $MAIN -replace '^\s*([^\|]+?)\s*\|\s*([^\|]+?)\s*\|\s*([^\|]+?)\s+\|.*$','$1|$2|$3' | ForEach-Object {
   
		$status,$name,$value = $_ -split '\|';
		$sensor,$name = $name -replace "\(" -split "\)\s+";
		$unit = $null;

		$value = $value -replace '\/\d+F$','';
		
		if( $value -match "^(.*?)(\sV|\sRPM|C)$" ) {
			$value = $matches[1];
			$unit = $matches[2];
			
		}

    $_ =
@"
    status = $status
    name = $name
    value = $value
    sensor = $sensor
    unit = $unit
"@

    $_ = ConvertFrom-StringData -StringData $_;
    New-Object -TypeName PSObject -Property $_;
	
	}

	$MAIN
	
}

Function Func-Range {

	Param (
		[single]$Value
	)

	if( $Critical -and $Critical[0] -le $Critical[1] -and $Value -ge $Critical[0] -and $Value -le $Critical[1] ) {
	
	$OUTPUT
	exit $State.Critical
	
	} elseif( $Warning -and $Warning[0] -le $Warning[1] -and $Value -ge $Warning[0] -and $Value -le $warning[1] ) {
	
	$OUTPUT
	exit $State.Warning
	
	} elseif( $Critical -and $Critical[0] -ge $Critical[1] -and ($Value -ge $Critical[0] -or $Value -le $Critical[1]) ) {
	
	$OUTPUT
	exit $State.Critical
	
	} elseif( $Warning -and $Warning[0] -ge $Warning[1] -and ($Value -ge $Warning[0] -or $Value -le $warning[1]) ) {
	
	$OUTPUT
	exit $State.Warning
	
	} else {
	
	$OUTPUT
	exit $State.Ok
	
	}
}

Function Func-Status {

	Param (
	
		[string]$Status
	
	)

	if ( $Status -ne "OK" -Or $NotOK -ne $null ) {
	
		$OUTPUT
		exit $State.Critical
		
	} else {
		
		$OUTPUT
		exit $State.Ok
	
	}
}

if ( Test-Path $CacheFile ) {
		if ( (Get-Item $CacheFile).LastWriteTime -le $TimeLimit -Or $CacheFileContent.Length -le 150 ) {
			$IPMI > $CacheFile	
		} 
} else {	
	$IPMI > $CacheFile
}
	
$CacheFileContent = Get-Content -Path $CacheFile | Out-String

if ($(Select-String -Path $CacheFile -Pattern "Completion Code" -Quiet) -eq $true) {
	$NeedResetMsg
	exit $State.Warning	
}

if( $CacheFileContent -match "Can not find a valid IPMI device." ) {
	$NotFoundMsg
	exit $State.Critical
}

$LastWrite = (Get-Item $CacheFile).LastWriteTime

switch ($SensorName) {
	"CPU Temp" {
	
		$CPUTemp = Func-ParseMain | where {$_.name -match "CPU\d Temp"}
		$CPUTemp = $CPUTemp | where {$_.value -ne "N/A"}

		ForEach ( $Data in $CPUTemp ) {
		
			$OUTPUT += ($Data.name)+": "+($Data.status)+". "
			
		}
		
		$NotOK = $CPUTemp.Status | where { $_ -ne "OK" }

		Func-Status -Status $Data.status
		break

	}
	"Power Supply" {
	
		$PowerSupply = Func-ParseMain | where {$_.Name -match "Power Supply" -Or $_.Name -match "PS Status"}
		$PowerSupply = $PowerSupply | where {$_.value -ne "N/A"}

		ForEach ( $Data in $PowerSupply ) {
		
			$OUTPUT += ($Data.name)+": "+($Data.status)+". "
			
		}
		
		Func-Status -Status $Data.status
		break

	}
	"CPU Overheat" {
	
		$CPUOverheat = Func-ParseMain | where {$_.name -match "CPU Overheat"}
		$CPUOverheat = $CPUOverheat | where {$_.value -ne "N/A"}

		ForEach ( $Data in $CPUOverheat ) {
		
			$OUTPUT += ($Data.name)+": "+($Data.status)+". "
			
		}
		
		Func-Status -Status $Data.status
		break
		
	}
	default {
	
		$Default = Func-ParseMain | where {$_.name -match $SensorName}
		$Default = $Default | where {$_.value -ne "N/A"}
		
		ForEach ( $Data in $Default ) {
		
			$OUTPUT += ($Data.name)+": "+($Data.value)+" "+($Data.unit)
			$OUTPUT += "|"+($SensorName.replace(' ',''))+"="+($Data.value)+";"+($WarningLine)+";"+($CriticalLine)

		}
		
		if ( $OUTPUT -eq $null ) {

			Write-Host "Sensor does not exists or CacheFile = null!"
			exit $State.Warning

		} else {

			Func-Range -Value $Data.value

		}
	}
}

#
# TODO: generate nagios config
# Temperature range for Supermicro: warning - 35, critical - 45  