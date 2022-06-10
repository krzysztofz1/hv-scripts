Param(

	[string]$VirtualDiskLetter = "I",

	[string]$VirtualDiskName = "NOBACKUP",

	[string]$SmbShareName = "hiSSD",

	[string]$SmbSharePath = "I:\",

	[string]$SmbShareFullAccess = ""
)



$CanPoolPhysicalDisks = ( Get-StorageSubSystem -FriendlyName "Storage Spaces*" | Get-PhysicalDisk -CanPool $True
 )
$CanPoolCount = $CanPoolPhysicalDisks.Count



Function Func-CreateStorage {

	Param (

		[object]$PhysicalDisks = $CanPoolPhysicalDisks,

		[string]$VirtualDiskFriendlyName = $VirtualDiskName,

		[string]$ResiliencySettingName,

		[string]$Letter = $VirtualDiskLetter

	)

	
	Write-Host -ForegroundColor Green "Creating StoragePool..."

	New-StoragePool -FriendlyName storage -StorageSubsystemFriendlyName "Storage Spaces*" -PhysicalDisks $PhysicalDisks | Out-Null

	Set-StoragePool -FriendlyName storage -IsPowerProtected $true -RetireMissingPhysicalDisks Always | Out-Null
	
	Write-Host -ForegroundColor Green "Creating VirtualDisk..."

	New-VirtualDisk -StoragePoolFriendlyName storage -FriendlyName $VirtualDiskFriendlyName -UseMaximumSize -ProvisioningType Fixed -ResiliencySettingName $ResiliencySettingName | Out-Null

	
	Write-Host -ForegroundColor Green "Formatting..."

	$GetDisk = Get-Disk -FriendlyName "Microsoft Storage Space Device"
 
 	Initialize-Disk -Number $GetDisk.Number | Out-Null

	New-Partition -DiskNumber $GetDisk.Number -UseMaximumSize -DriveLetter $Letter | Out-Null

	Format-Volume -DriveLetter $Letter -Confirm:$false | Out-Null

}

Function Func-CreateSmbShare {

	Param (

		[object]$Name = $SmbShareName,

		[string]$Path = $SmbSharePath,

		[string]$FullAccess = $SmbShareFullAccess

	)

	New-SmbShare -Name $Name -Path $Path -FullAccess "RBX\RBX Servers", "RBX\Administrator", "NT Virtual Machine\Virtual Machines", "Builtin\Administrators"
	
}
switch ($CanPoolCount) {
	{ $_ -eq 2 } {
		Func-CreateStorage -ResiliencySettingName Mirror
		Func-CreateSmbShare

		break
 
	}        
		
	{ $_ -gt 2 } {
			
		Func-CreateStorage -ResiliencySettingName Parity
		Func-CreateSmbShare

		break
	} 
		
	{ $_ -lt 2 } {

		Write-Host -ForegroundColor Red "Error: not enought disks to create StoragePool. CanPoolCount=$CanPoolCount"
Func-CreateSmbShare
		break

	}

}
