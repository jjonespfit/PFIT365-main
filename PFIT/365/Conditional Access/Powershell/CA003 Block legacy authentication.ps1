################### Block Legacy Auth Policy ######
$PolicyName = "CA003: Block legacy authentication"
$Checkpolicy = Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$PolicyName'"
$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA003: Block legacy authentication')" | Select-Object ID
if ($null -eq $Checkpolicy) {
  $params = @{
    DisplayName = $PolicyName
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
        ExcludeGroups = @(
          $ExcludeCAGroups.Id
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
  New-MgIdentityConditionalAccessPolicy -BodyParameter $params | Out-Null
            Write-Host "Created policy $PolicyName."
        } else {
            Write-Host "Skipped policy $PolicyName because it already exists."
        }