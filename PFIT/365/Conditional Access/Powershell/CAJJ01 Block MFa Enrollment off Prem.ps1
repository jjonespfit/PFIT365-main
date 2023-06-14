$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA00JJ01: Block MFA Enrollment off prem')" | Select-Object ID

$params = @{
  DisplayName = "CAJJ001: Block MFA Reistratoin off Prem"
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