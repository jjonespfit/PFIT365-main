$params = @{
  DisplayName = "CA003: Block legacy authentication"
  State = "disabled"
  Conditions = @{
    ClientAppTypes = @(
        "exchangeActiveSync",
        "other"
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
    }
    Locations = @{
      IncludeLocations = @(
        "All"
      )
      ExcludeLocations = @()
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