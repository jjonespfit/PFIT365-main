###################   Default Block Policy ########
$PolicyName = "CA002: Default Block - Travel Users Exclusion"
$Checkpolicy = Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$PolicyName'"
$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA002: Default Block - Travel Users Exclusion')" | Select-Object ID
$AllowedCountriesNamedLocation = Get-MgIdentityConditionalAccessNamedLocation -Filter "startswith(DisplayName,'Allowed Countries')" | Select-Object ID

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
        ExcludeLocations =@(
          $AllowedCountriesNamedLocation.id
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