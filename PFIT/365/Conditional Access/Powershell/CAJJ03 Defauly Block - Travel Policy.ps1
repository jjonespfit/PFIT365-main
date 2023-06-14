$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA002: Default Block - Travel Exclusion')" | Select-Object ID
$TravelCountriesNamedLocation Get-MgIdentityConditionalAccessNamedLocation -Filter "startswith(DisplayName,'Travel Countries')" | Select-Object ID
$AllowedCountriesNamedLocation Get-MgIdentityConditionalAccessNamedLocation -Filter "startswith(DisplayName,Allowed Countries')" | Select-Object ID

$params = @{
  DisplayName = "CAJJ003: Default Block - Travel Policy"
  State = "disabled"
  Conditions = @{
    ClientAppTypes = @(
      "All"
    )
    Applications = @{
      IncludeApplications = @(
        "All"
      )
    }
    users = @{
      IncludeUsers = @(
        $ExcludeCAGroups.Id
       )
    }
    Locations = @{
      IncludeLocations = @(
        "All"
      )
      ExcludeLocations =@(
        $AllowedCountriesNamedLocation.id
        $TravelCountriesNamedLocation.id
      )
    }
   }
   GrantControls = @{
     Operator = "OR"
     BuiltInControls = @(
      "Block"
     )
   }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params