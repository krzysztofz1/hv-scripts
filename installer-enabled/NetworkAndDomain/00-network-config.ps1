Param(

	[string]$HostName = $env:ComputerName

)


$hArray = $HostName.Split('-') 


Function Func-NetworkConfig {

	Param (
		
		[string]$IPAddr,

		[string]$DefaultGateway,

		[string]$InternalGateway,

		[int]$VlanId,
		
		[object]$DnsServers
	)

	

	New-NetLbfoTeam -Name netTeam -TeamMembers * -TeamingMode SwitchIndependent -LoadBalancingAlgorithm Dynamic -Confirm:$false

	New-VMSwitch -AllowManagementOS $true -Name "guests" -NetAdapterName netTeam

	Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName guests -Access -VlanId $VlanId

	New-NetIPAddress -InterfaceAlias "vEthernet (guests)" -IPAddress $IPAddr -PrefixLength 24 -DefaultGateway $DefaultGateway


	Set-DnsClientServerAddress -InterfaceIndex (Get-NetAdapter -name "vEthernet (guests)").ifIndex -ServerAddresses $DnsServers

	
	route -p add 10.0.0.0 mask 255.0.0.0 $InternalGateway

	route -p add 62.181.0.0 mask 255.255.224.0 $InternalGateway

}





switch -Exact ($hArray[0]) { 
        
	"HV" {
		
$IP = "10.80.2."+$hArray[-1]

		while ( $correct -ne "y" ) { 
			$correct = read-host "is this $IP correct ? (y/n)"; 
			if ( $correct -ne "y" ) { 
				$IP = read-host "Enter IP address" 
			} 
		}

		Func-NetworkConfig -IPAddr $IP -DefaultGateway 10.80.2.5 -InternalGateway 10.80.2.1 -VlanId 702 -DnsServers @("10.80.1.30")

		break

	}

	default {
	
		$IP = "10.80.3."+$hArray[-1]

		while ( $correct -ne "y" ) { 
			$correct = read-host "is this $IP correct ? (y/n)"; 
			if ( $correct -ne "y" ) { 
				$IP = read-host "Enter IP address" 
			}
		}

		Func-NetworkConfig -IPAddr $IP -DefaultGateway 10.80.3.5 -InternalGateway 10.80.3.1 -VlanId 703 -DnsServers @("10.80.1.30")

		break
		
	}	

}

Write-Host -ForegroundColor Green "Configuring network... wait 45 sec..."

Start-Sleep -s 45

