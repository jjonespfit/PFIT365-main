
$params = @{
  DisplayName = "CA010: Block access for unknown or unsupported device platform"
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
    Platforms =@{
      IncludePlatforms =@(
        "All"
      )
      ExcludePlayforms =@(
        "android",
        "iOS",
        "windows",
        "macOS"
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
      "Block"
     )
   }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params