$ALLOWED = @("SATA","RAID","SAS")

$OTHER = ( Get-PhysicalDisk | where { $_.bustype -notin $ALLOWED } )

if( $OTHER.length -gt 0 ) {
  
  $OTHER | Select model,serial*,bustype,mediatype,size | ft

  ""

  write-warning ""
  write-warning "Found disks with not allowed BusType !"
  write-warning ""
  write-warning "Allowed BusTypes: $( $ALLOWED -join "," )"
  write-warning ""
  
  write-error "NOT allowed BusType on physical disk(s)"

  exit 1
}

exit 0