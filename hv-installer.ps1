Param(
	[string]$Stage="NameChange"
)


#$ErrorActionPreference = "Stop"

$RegRunOnceKey = "ResumeScript"
$RegRunOncePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"

$PSPath = "$PSHome\powershell.exe"
$Script = $myInvocation.MyCommand.Definition

$ScriptDir = ($myInvocation.MyCommand.Path).TrimEnd($myInvocation.MyCommand.Name)
$Log = $ScriptDir+"logs\"+((Get-Date -Format "s").Replace(':',''))+"_"+$Stage+".log"

"STAGE: $Stage"

function Func-ResumeScript {
	
	Param(
		[string]$Script,
		[string]$Stage
	)
	
  Set-ItemProperty -Path $RegRunOncePath -Name $RegRunOnceKey -Value "$PSPath $Script -Stage $Stage"
	Restart-Computer
}

switch ($Stage) {

	"NameChange" {

		Get-ChildItem "$PSScriptRoot\installer-enabled\NameChange" | 
      Where { $_.Extension -eq ".ps1" -and $_.Name -notlike "__*" } | 
      ForEach { . $_.FullName; if( !$? ) { exit 1 }  } *>&1 | 
      Tee-Object -FilePath $Log -Append
      
		Func-ResumeScript -Script $Script -Stage "NetworkAndDomain"

		break	
	}

	"NetworkAndDomain" {

		Get-ChildItem "$PSScriptRoot\installer-enabled\NetworkAndDomain" | 
      Where { $_.Extension -eq ".ps1" -and $_.Name -notlike "__*" } | 
      ForEach { . $_.FullName } *>&1 |
      Tee-Object -FilePath $Log -Append

		Func-ResumeScript -Script $Script -Stage "Config"

		break
	}

	"Config" {

		Get-ChildItem "$PSScriptRoot\installer-enabled\Config" | 
      Where { $_.Extension -eq ".ps1" -and $_.Name -notlike "__*" } | 
      ForEach { . $_.FullName } *>&1 |
      Tee-Object -FilePath $Log -Append
      
    Get-ChildItem "$PSScriptRoot\installer-enabled\Monitoring" | 
      Where { $_.Extension -eq ".ps1" -and $_.Name -notlike "__*" } | 
      ForEach { . $_.FullName } *>&1 |
      Tee-Object -FilePath $Log -Append
      
      
		break
	}


	default {
		"Error: selected stage doesn't exists!"
	}

} 
