$params = @{
  DisplayName = "CA005: Require multi-factor authentication for guest access"
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
    }
    users = @{
      IncludeUsers = @(
        "GuestsOrExternalUsers"
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
       "mfa"
     )
   }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params