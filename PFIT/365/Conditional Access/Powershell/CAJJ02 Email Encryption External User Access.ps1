
$params = @{
  DisplayName = "CAJJ002: Email Encryption External User Access"
  State = "disabled"
  Conditions = @{
    ClientAppTypes = @(
      "All"
    )
    Applications = @{
      IncludeApplications = @(
        "All"
      )
      ExcludeApplications = @(
        "00000012-0000-0000-c000-000000000000"
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
      ExcludeLocations =@(
        "AllTrusted"
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