################### Block MFA Enrollment from Non Trusted Locations #######################
$PolicyName = "CA012: Block MFA Enrollment from Non Trusted Locations"
$Checkpolicy = Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$PolicyName'"
$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA012: Block MFA Enrollment from Non Trusted Locations')" | Select-Object ID
if ($null -eq $Checkpolicy) {
  $params = @{
    DisplayName = $PolicyName
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
         ExcludeGroups = @(
          $ExcludeCAGroups.Id
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
  New-MgIdentityConditionalAccessPolicy -BodyParameter $params | Out-Null
            Write-Host "Created policy $PolicyName."
        } else {
            Write-Host "Skipped policy $PolicyName because it already exists."
        }
