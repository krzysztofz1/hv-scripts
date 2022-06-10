$name = Read-Host "please enter host name (blank = This host) "
if ($name){
} else {

$name = (Get-Item env:\Computername).Value 
}
$filepath = (Get-ChildItem env:\userprofile).value 
 
## Email Setting 
 
$to = Read-Host "please enter email address (blank=raporty@wdc.pl) "

if ($to){
} else {
$to = "raporty@wdc.pl"
}

$smtp = "mx0.rubikon.pl"  
$subject = "Konfiguracja sprzêtowa $name"  
$attachment = "$filepath\$name.html" 
$from =  "$name <mail@$name.wdc.pl>" 
 
if (Test-Path  ("$filepath\$name.html")) {
Remove-Item ("$filepath\$name.html")}
 
 
 
############################################### 
 
 $a = "<!--mce:0-->" 
 
##### 
 
  
 
# MotherBoard: Win32_BaseBoard # You can Also select Tag,Weight,Width  
$mboard = Get-WmiObject -ComputerName $name  Win32_BaseBoard |  Select Name,Manufacturer,Product,SerialNumber,Status | ConvertTo-html -Fragment -As LIST -PreContent "<H2> MotherBoard Information</H2>" 
 
# BIOS 
$bios = Get-WmiObject win32_bios -ComputerName $name  | Select Manufacturer,Name,BIOSVersion,ListOfLanguages,PrimaryBIOS,ReleaseDate,SMBIOSBIOSVersion,SMBIOSMajorVersion,SMBIOSMinorVersion | ConvertTo-html -Fragment -As LIST -PreContent "<H2> BIOS Information</H2>"  
 
# System Info 
$sysinfo = Get-WmiObject Win32_ComputerSystemProduct -ComputerName $name  | Select Vendor,Version,Name,IdentifyingNumber,UUID | ConvertTo-html -Fragment -As LIST -PreContent "<H2> System Information</H2>"
 
# Hard-Disk 
$disks = Get-WmiObject win32_diskDrive -ComputerName $name  | select Model,SerialNumber,InterfaceType,Partitions, @{n='Size';e={[int]($_.Size/1000/1000/1000)}} | ConvertTo-html Model,SerialNumber,InterfaceType,Size,Partitions -Fragment -As LIST -PreContent "<H2> Disk Information</H2>" 
 
# NetWork Adapters -ComputerName $name 
$network_interfaces  = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $name -Filter "IpEnabled = TRUE"   |select Description, DHCPEnabled, @{n='IPAddress';e={($_.IPAddress[0])}}, @{n='DefaultIPGateway';e={($_.DefaultIPGateway[0])}}, MACAddress | ConvertTo-html -Fragment -As LIST -PreContent "<H2> Network Configuration</H2>" 
 
# Memory 
$memory = Get-WmiObject Win32_PhysicalMemory -ComputerName $name | Where-Object{$_.Speed -gt 100} |select BankLabel,DeviceLocator,@{n='Size';e={[int]($_.Capacity/1GB)}},Manufacturer,PartNumber,SerialNumber,Speed  | ConvertTo-html -Fragment -As LIST -PreContent "<H2> Memory Information</H2>" 
 
# Processor  
$cpu = Get-WmiObject Win32_Processor -ComputerName $name  | Select Name,Manufacturer,Caption,DeviceID,CurrentClockSpeed,CurrentVoltage,DataWidth,L2CacheSize,L3CacheSize,NumberOfCores,NumberOfLogicalProcessors,Status   | ConvertTo-html -Fragment -As LIST -PreContent "<H2> CPU Information</H2>" 
 

# basic info template
$os= get-wmiobject win32_operatingsystem -ComputerName $name| select Name, @{Name="Installed"; Expression={$_.ConvertToDateTime($_.InstallDate)}} | ConvertTo-html -Fragment -As LIST -PreContent "<H2> OS Information</H2>" 
#$a = $a.Installed
#$a = '{0:dd/MM/yyy}' -f $a
#$a = [datetime]::Parse($a)
#$os = get-wmiobject win32_operatingsystem | select Name
#$os = $os.Name.split('|')[0]

$date = Get-Date -Format dd/MM/yyyy
$body = ''




$body = $body + $mboard
$body = $body + $cpu
$body = $body + $network_interfaces
$body = $body + $bios
$body = $body + $os

$body = $body + $disks
 

$body = $body + $memory
$body >> "$filepath\$name.html" 
#### Sending Email 
 
Send-MailMessage -To $to -Subject $subject -From $from -SmtpServer $smtp -BodyAsHtml $body -Attachment "$filepath\$name.html"  -Encoding "UTF8"  