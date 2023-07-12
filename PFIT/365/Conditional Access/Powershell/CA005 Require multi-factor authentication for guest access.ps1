################### MFA for Guest Users Policy ######
$PolicyName = "CA005: Require multi-factor authentication for guest access"
$Checkpolicy = Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$PolicyName'"
$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA005: Require multi-factor authentication for guest access')" | Select-Object ID
if ($null -eq $Checkpolicy) {
  $params = @{
    DisplayName = $PolicyName
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
         ExcludeGroups = @(
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
      operator = "OR"
      builtInControls = @(
      )
      customAuthenticationFactors = @(
      )
      termsOfUse = @(
      )
      authenticationStrength = @{
        id = "00000000-0000-0000-0000-000000000002"
      }
    }
  }
  New-MgIdentityConditionalAccessPolicy -BodyParameter $params | Out-Null
            Write-Host "Created policy $PolicyName."
        } else {
            Write-Host "Skipped policy $PolicyName because it already exists."
        }
