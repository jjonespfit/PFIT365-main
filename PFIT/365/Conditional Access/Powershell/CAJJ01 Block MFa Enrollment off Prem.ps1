
$params = @{
  DisplayName = "CA002: Block MFA Reistratoin off Prem"
  State = "disabled"
  Conditions = @{
    ClientAppTypes = @(
      "All"
    )
    Applications = @{
      IncludeUserActions =@(
        "urn:user:registersecurityinfo"
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