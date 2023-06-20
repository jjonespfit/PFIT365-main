$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA002: Default Block - Travel Exclusion')" | Select-Object ID
$AllowedCountriesNamedLocation = Get-MgIdentityConditionalAccessNamedLocation -Filter "startswith(DisplayName,Allowed Countries')" | Select-Object ID

$params = @{
  DisplayName = "CA002: Default Block"
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
        "All"
       )
       ExcludeUsers =@(
        $ExcludeCAGroups.id
       )
    }
    Locations = @{
      IncludeLocations = @(
        "All"
      )
      ExcludeLocations =@(
        "AllTrusted"
        $AllowedCountriesNamedLocation.id
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