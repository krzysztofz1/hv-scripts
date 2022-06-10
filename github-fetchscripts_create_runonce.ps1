$RegRunOnceKey = "CloneGitRepo"
$RegRunOncePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
$PSPath = "$PSHome\powershell.exe"
$Script = "C:\hv-scripts\github-fetchscripts_run.ps1"
$Date = ((Get-Date -Format "s").Replace(':','').Replace('-',''))
Set-ItemProperty -Path $RegRunOncePath -Name $RegRunOnceKey -Value "$PSPath $Script > c:\hv-scripts\logs\github-fetchscripts_$Date.log"
Get-ItemProperty -Path $RegRunOncePath 