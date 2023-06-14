Connect-MgGraph -Scopes 'Policy.ReadWrite.ConditionalAccess'

$CountryNameLocations =@(
    "Allowed Countries"
    "Travel Countries"
)

foreach($Location in $CountryNameLocations){

$namedLocation = Get-MgIdentityConditionalAccessNamedLocation -Filter "DisplayName eq '$Location'"
if ($null -eq $namedLocation) {
    $body = @{
        "@odata.type" = "#microsoft.graph.countryNamedLocation" 
        DisplayName = $Location 
        CountriesAndRegions = @("US") 
        IncludeUnknownCountriesAndRegions = $false 
    }
    $namedLocation = New-MgIdentityConditionalAccessNamedLocation -BodyParameter $body
    Write-Host "Created named location $Location."
} else {
    Write-Host "Skipped named location $location because it already exists."
}
}



Param ([Parameter(Mandatory = $true)] [string[]] $onPremIps)      

$IPAddress = $onPremIps

$params = @{
"@odata.type" = "#microsoft.graph.ipNamedLocation"
    DisplayName = "OnPrem"
    IsTrusted = $true
    IpRanges = @(
    @{
        "@odata.type" = "#microsoft.graph.iPv4CidrRange"
        CidrAddress = "$IPAddress"
    }
)
}

New-MgIdentityConditionalAccessNamedLocation -BodyParameter $params
