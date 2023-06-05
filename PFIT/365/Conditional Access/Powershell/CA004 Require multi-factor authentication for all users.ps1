$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA004: Require multi-factor authentication for allusers_Restricted')" | Select-Object ID

$params = @{
  DisplayName = "CA004: Require multi-factor authentication for all users"
  State = "disabled"
  Conditions = @{
    ClientAppTypes = @(
      "browser", 
      "mobileAppsAndDesktopClients"
    )
    Applications = @{
      IncludeApplications = @(
        "All"
      )
      ExcludeApplications = @(
        "0000000a-0000-0000-c000-000000000000",
        "d4ebce55-015a-49b5-a083-c84d1797ae8c"
      )
    }
    users = @{
      IncludeUsers = @(
        "All"
       )
       ExcludeGroups = @(
        $ExcludeCAGroups.Id
       )
    }
    Locations = @{
      IncludeLocations = @(
        "All"
      )
      ExcludeLocations = @(
        "AllTrusted"
      )
    }
   }
   GrantControls = @{
     Operator = "OR"
     BuiltInControls = @(
       "mfa"
     )
   }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params