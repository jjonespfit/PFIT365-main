################### Require Compliant Device Policy IOS/ Andriod Report Only #############
$PolicyName = "CA009.7: Require Compliant Device IOS-Android Report Only"
$Checkpolicy = Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$PolicyName'"
if ($null -eq $Checkpolicy) {
  $params = @{
    DisplayName = $PolicyName
    State = "enabledForReportingButNotEnforced"
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
          "android",
          "iOS"
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
