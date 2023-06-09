###################   Admin MFA Policy ############
$PolicyName = "CA001: Require multi-factor authentication for admins"
$Checkpolicy = Get-MgIdentityConditionalAccessPolicy -Filter "DisplayName eq '$PolicyName'"
$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA001: Require multi-factor authentication for admins')" | Select-Object ID
if ($null -eq $Checkpolicy) {
  $params = @{
    DisplayName = "$policyName"
    State = "disabled"
    Conditions = @{
      ClientAppTypes = @(
        "mobileAppsAndDesktopClients"
        "browser"
      )
      Applications = @{
        IncludeApplications = @(
          "All"
        )
      }
      users = @{
        ExcludeUsers =@(
          $Z1
         )
        IncludeRoles = @(
          "62e90394-69f5-4237-9190-012177145e10",
          "194ae4cb-b126-40b2-bd5b-6091b380977d",
          "f28a1f50-f6e7-4571-818b-6a12f2af6b6c",
          "29232cdf-9323-42fd-ade2-1d097af3e4de",
          "b1be1c3e-b65d-4f19-8427-f6fa0d97feb9",
          "729827e3-9c14-49f7-bb1b-9608f156bbb8",
          "b0f54661-2d74-4c50-afa3-1ec803f12efe",
          "fe930be7-5e62-47db-91af-98c3a49a38b1",
          "c4e39bd9-1100-46d3-8c65-fb160da0071f",
          "9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3",
          "158c047a-c907-4556-b7ef-446551a6b5f7",
          "966707d0-3269-4727-9be2-8c3a10f19b9d",
          "7be44c8a-adaf-4e2a-84d6-ab2649e08a13",
          "e8611ab8-c189-46e8-94e1-60213ab1f814",
          "fdd7a751-b60b-444a-984c-02652fe8fa1c",
          "a9ea8996-122f-4c74-9520-8edcd192826c",
          "44367163-eba1-44c3-98af-f5787879f96a",
          "7698a772-787b-4ac8-901f-60d6b08affd2",
          "f2ef992c-3afb-46b9-b7cf-a126ee74c451",
          "2b745bdf-0803-4d80-aa65-822c4493daac",
          "11648597-926c-4cf3-9c36-bcebb0ba8dcc",
          "5f2222b1-57c3-48ba-8ad5-d4759f1fde6f"
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
