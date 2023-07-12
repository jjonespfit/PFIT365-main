#################### Encryptino Allow for External Users Policy ############
$PolicyName = "CA013: Email Encryption External User Access"
$Checkpolicy = Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$PolicyName'"
$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA013: Email Encryption External User Access')" | Select-Object ID
if ($null -eq $Checkpolicy) {
  $params = @{
    DisplayName = $PolicyName
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
