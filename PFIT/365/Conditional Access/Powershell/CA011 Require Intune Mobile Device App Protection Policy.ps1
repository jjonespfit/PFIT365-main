################### Require App Protection Policy IOS/Andriod ################
$PolicyName = "CA011: Require Intune Mobile Device App Protection Policy"
$Checkpolicy = Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$PolicyName'"
$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA011: Require Intune Mobile Device App Protection Polic')" | Select-Object ID
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
          "d4ebce55-015a-49b5-a083-c84d1797ae8c"
        )
      }
      Platforms =@{
        IncludePlatforms =@(
          "android",
          "iOS"
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
       Operator = "AND"
       BuiltInControls = @(
        "approvedApplication", 
        "compliantApplication"
       )
     }
  }
  New-MgIdentityConditionalAccessPolicy -BodyParameter $params | Out-Null
            Write-Host "Created policy $PolicyName."
        } else {
            Write-Host "Skipped policy $PolicyName because it already exists."
        }