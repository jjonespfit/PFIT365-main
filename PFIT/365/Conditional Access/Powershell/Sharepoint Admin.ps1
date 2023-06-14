$SPDomain = (Get-MgDomain | Where-Object { $_.IsDefault -eq $true }).id

$PrimaryDomain = $SPDomain
$PrimarySPSitePrefix = $PrimaryDomain.Split('.')[0]

$SP_URL= "$PrimarySPSitePrefix-admin.sharepoint.com"
 
Connect-SPOService -Url https://"$sp_url"
Set-SPOTenant -SharingCapability Disabled 

Disconnect-SPOService