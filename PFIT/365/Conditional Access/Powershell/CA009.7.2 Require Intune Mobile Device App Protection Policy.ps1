
$params = @{
  DisplayName = "CA009.7.2: Require Intune Mobile Device App Protection Policy"
  State = "disabled"
  Conditions = @{
    ClientAppTypes = @(
      "All"
    )
    Applications = @{
      IncludeApplications = @(
        "browser", 
        "mobileAppsAndDesktopClients"
      )
      ExcludeApplications =@(
        "d4ebce55-015a-49b5-a083-c84d1797ae8c"
      )
    }
    Platforms =@{
      IncludePlatforms =@(
        "android",
        "iOS"
      )
    }
    users = @{
      IncludeUsers = @(
        "All"
       )
    }
    Locations = @{
      IncludeLocations = @(
        "All"
      )
    }
   }
   GrantControls = @{
     Operator = "AND"
     BuiltInControls = @(
      "approvedApplication", 
      "compliantApplication"
     )
   }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params