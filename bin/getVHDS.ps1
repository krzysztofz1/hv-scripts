Param(

  [Parameter(
    Position=0, 
    Mandatory=$true, 
    ValueFromPipeline=$true,
    ValueFromPipelineByPropertyName=$true)
  ]
  [GUID]$VMID,

  [Parameter(
    Position=0, 
    Mandatory=$true)
  ]
  [string]$DestinationStoragePath,
  
  [Parameter(
    ValueFromPipelineByPropertyName=$true)
  ]
  [string]$ComputerName = "."
)

$V = Get-VM -ID $VMID -ComputerName $ComputerName

if( !$V ) {
  write-host "VM not found"
  exit;
}

$D = @();
$D += $V.harddrives.path

if( $D.length -lt 1 ) {
  write-host "VM doesn't have hard disks"
  exit;
}

$D | foreach { $i=0 } {
  write-host "$i : $_";
  $i++;
}

while( $SELECTION.length -lt 1 ) {
  $SELECTION = read-host "Which disks to move to $DestinationStoragePath ?"
  $SELECTION = $SELECTION -split "[^\d+]" | Where { $_ -match "^\d+$" -and $_ -lt $D.length -and $_ -ge 0 }
}

$VHDS = @();

$SELECTION | Foreach {
 
  $index = [int]$_;
  $source = $D[$index];
  $filename = split-path -path $source -leaf
  $destination = "$DestinationStoragePath\Virtual Hard Disks\$filename"
  
  $VHDS += @{
    "SourceFilePath" = $source;
    "DestinationFilePath" = $destination;
  }
}

$VHDS