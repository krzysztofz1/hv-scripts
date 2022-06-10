$VHDPath = "I:\"
$VMPath = "I:\"

Enable-VMMigration
Set-VMHost -VirtualHardDiskPath $VHDPath -VirtualMachinePath $VMPath -UseAnyNetworkForMigration $true -VirtualMachineMigrationAuthenticationType CredSSP 
Set-VMReplicationServer -ReplicationEnabled $true –AllowedAuthenticationType Kerberos -KerberosAuthenticationPort 8080 –ReplicationAllowedFromAnyServer $true –DefaultStorageLocation $VHDPath