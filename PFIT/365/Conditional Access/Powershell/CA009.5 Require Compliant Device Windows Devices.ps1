################### Require Compliant Device Windows ###########
$PolicyName = "CA009.5: Require Compliant Device - Windows Devices"
$Checkpolicy = Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$PolicyName'"
$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA009.5: Require Compliant Device - Windows Devices_Restricted')" | Select-Object ID
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
        ExcludeApplications =@(
          "0000000a-0000-0000-c000-000000000000",
          "d4ebce55-015a-49b5-a083-c84d1797ae8c",
          "45a330b1-b1ec-4cc1-9161-9f03992aa49f"
        )
      }
      Platforms =@{
        IncludePlatforms =@(
          "windows"
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
      }
     }
     GrantControls = @{
       Operator = "OR"
       BuiltInControls = @(
         "compliantDevice"
       )
     }
  }
  New-MgIdentityConditionalAccessPolicy -BodyParameter $params | Out-Null
            Write-Host "Created policy $PolicyName."
        } else {
            Write-Host "Skipped policy $PolicyName because it already exists."
        }