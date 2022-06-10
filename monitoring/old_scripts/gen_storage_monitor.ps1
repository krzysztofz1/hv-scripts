$email_address = Read-Host "Please enter your email address"

$hostname = Get-Content env:computername
################################################################################
# Poniżej część odpowiedzialna za tworzenie skryptów do monitorowania macierzy #
################################################################################

$arrays = Get-VirtualDisk | findstr -i Healthy

$file_name = $arrays.split()
$file_name = $file_name[0]
$file_name = $file_name.replace(' ','').replace("`n","").replace("`r","").replace("^","")
#echo $file_name

echo ""$"STATE_OK=0
"$"STATE_CRITICAL=2

"$"array_ok = ""$arrays""
"$"array = Get-VirtualDisk | findstr -i Healthy

"$"check = "$"array_ok.CompareTo("$"array)

if ( "$"check -eq 0 ) {

	"$"STATE="$"STATE_OK
	"$"DESCRIPTION="$"array

} else {

	"$"critical='$file_name Array Error!'
	"$"STATE="$"STATE_CRITICAL
	"$"DESCRIPTION="$"critical

}

echo "$"DESCRIPTION
exit "$"STATE
" > "c:\Program Files\NSClient++\scripts\check_array_$file_name.ps1"
echo "Script location: c:\Program Files\NSClient++\scripts\check_array_$file_name.ps1"
echo "check_array_$file_name = cmd /c echo scripts\check_array_$file_name.ps1; exit(`$lastexitcode) | powershell.exe -executionpolicy unrestricted -command -" |out-file -append -encoding ASCII -filepath "c:\Program Files\NSClient++\nsclient.ini"

$body ="define service {<br>
	host_name               wdc - $hostname<br>
        max_check_attempts      3<br>
        service_description     $file_name array state - NRPE<br>
        check_command           check_nrpe!-c check_array_$file_name<br>
        contact_groups          admins<br>
        check_period            24x7<br>
}

"

##############################################################################
# Poniżej część odpowiedzialna za tworzenie skryptów do monitorowania dysków #
##############################################################################

$line_quantity = Get-WmiObject -Namespace "root/Microsoft/Windows/Storage" -Class MSFT_PhysicalDisk -Property FriendlyName, Operationalstatus, SerialNumber, HealthStatus | Format-Table SerialNumber, OperationalStatus, HealthStatus | Measure-Object -Line | Select-Object Lines -expand Lines
$line_quantity = $line_quantity - 4
$line_q 

$disk_sn = @(0) * $line_quantity
$disk_HealthStatus = @(0) * $line_quantity
$disk_Operationalstatus = @(0) * $line_quantity

$i=0
$j=0
while ($i -eq 0 ) {

	$disks = Get-WmiObject -Namespace "root/Microsoft/Windows/Storage" -Class MSFT_PhysicalDisk -Property Operationalstatus, SerialNumber, HealthStatus | Select-Object -skip $j -first 1

	$disk_sn[$j] = $disks | foreach {$_.SerialNumber} | out-string
	$disk_sn[$j] = $disk_sn[$j].replace(' ','')

	$disk_HealthStatus[$j] = $disks | foreach {$_.HealthStatus} | out-string
	$disk_HealthStatus[$j] = $disk_HealthStatus[$j].replace(' ','')

	$disk_Operationalstatus[$j] = $disks | foreach {$_.Operationalstatus} | out-string
	$disk_Operationalstatus[$j] = $disk_Operationalstatus[$j].replace(' ','')

	if (!$disk_sn[$j]) {
		$i++
		$count = $j-1
	}

	$j++

}


$i=0
while($i -le $count) {
	$disk_sns = echo $disk_sn[$i] | out-string
	$disk_sns = $disk_sns.replace(' ','').replace("`n","").replace("`r","").replace("^","")
	$disk_check_string = Get-WmiObject -Namespace "root/Microsoft/Windows/Storage" -Class MSFT_PhysicalDisk -Property FriendlyName, Operationalstatus, SerialNumber, HealthStatus | Format-Table SerialNumber, OperationalStatus, HealthStatus | out-string

	$disk_state = $disk_check_string | findstr -i $disk_sns



	echo ""$"STATE_OK=0
	"$"STATE_CRITICAL=2
	"$"disk_list = Get-WmiObject -Namespace "root/Microsoft/Windows/Storage" -Class MSFT_PhysicalDisk -Property FriendlyName, Operationalstatus, SerialNumber, HealthStatus | Format-Table SerialNumber, OperationalStatus, HealthStatus | out-string
	"$"disk_status_ok = ""$disk_state""
	"$"disk_status = "$"disk_list | findstr -i $disk_sns

	"$"check = "$"disk_status_ok.CompareTo("$"disk_status)

	if ( "$"check -eq 0 ) {

		"$"STATE="$"STATE_OK
		"$"DESCRIPTION="$"disk_status

	} else {

		"$"critical='$disk_sns Disk Error!'
		"$"STATE="$"STATE_CRITICAL
		"$"DESCRIPTION="$"critical

	}

	echo "$"DESCRIPTION
	exit "$"STATE
	" > "c:\Program Files\NSClient++\scripts\check_disk_TEST_$i.ps1"
	echo "Script location: c:\Program Files\NSClient++\scripts\check_disk_TEST_$i.ps1"
	echo "check_disk_TEST_$i = cmd /c echo scripts\check_disk_TEST_$i.ps1; exit(`$lastexitcode) | powershell.exe -executionpolicy unrestricted -command -" |out-file -append -encoding ASCII -filepath "c:\Program Files\NSClient++\nsclient.ini"


	$body = $body+"<br>define service {<br>
		host_name               wdc - $hostname<br>
			max_check_attempts      3<br>
			service_description     SN: $disk_sns disk state - NRPE<br>
			check_command           check_nrpe!-c check_disk_TEST_$i<br>
			contact_groups          admins<br>
			check_period            24x7<br>
	}
	"



	$i++
}

##############################################################################

if($email_address) {
	send-mailmessage -SmtpServer "mx0.rubikon.pl" -to "$email_address" -from "$hostnmae <mail@$hostname.wdc.pl>" -subject "Konfiguracja Nagios $hostname - dyski i macierze" -BodyAsHTML "$body"
}

net stop "NSClient++ (x64)"
net start "NSClient++ (x64)"
