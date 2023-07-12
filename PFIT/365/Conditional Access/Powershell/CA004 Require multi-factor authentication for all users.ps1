################### MFA for All Users Policy #######
$PolicyName = "CA004: Require multi-factor authentication for All Users"
$Checkpolicy = Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$PolicyName'"
$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA004: Require multi-factor authentication for allusers_Restricted')" | Select-Object ID
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
        ExcludeApplications = @(
          "0000000a-0000-0000-c000-000000000000",
          "d4ebce55-015a-49b5-a083-c84d1797ae8c"
        )
      }
      users = @{
        IncludeUsers = @(
          "All"
         )
         ExcludeUsers =@(
          $Z1
         )
         ExcludeGroups = @(
          $ExcludeCAGroups.Id

         )
      }
      Locations = @{
        IncludeLocations = @(
          "All"
        )
        ExcludeLocations = @(
          "AllTrusted"
        )
      }
     }
     grantControls = @{
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