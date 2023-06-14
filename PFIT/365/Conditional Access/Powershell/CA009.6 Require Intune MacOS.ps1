$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA009.6: Require Intune MacOS_Testing-Only')" | Select-Object ID

$params = @{
  DisplayName = "CA009.6 Require Intune MacOS"
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
      ExcludeApplications =@(
        "0000000a-0000-0000-c000-000000000000",
        "d4ebce55-015a-49b5-a083-c84d1797ae8c",
        "45a330b1-b1ec-4cc1-9161-9f03992aa49f"
      )
    }
    Platforms =@{
      IncludePlatforms =@(
        "macOS"
      )
    }
    users = @{
      IncludeUsers = @(
        "All"
       )
      ExcludeUsers =@(
        $ExcludeCAGroups.Id
      )
    }
    Locations = @{
      IncludeLocations = @(
        "All"
      )
    }
   }
   GrantControls = @{
     Operator = "OR"
     BuiltInControls = @(
       "compliantDevice"
     )
   }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params