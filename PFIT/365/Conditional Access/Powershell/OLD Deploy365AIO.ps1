# Define all required modules
$modules = 'Microsoft.graph','ExchangeOnlineManagement', 'MicrosoftTeams','Microsoft.Online.SharePoint.PowerShell'

# Find those that are already installed.
$installed = @((Get-Module $modules -ListAvailable).Name | Select-Object -Unique)

# Infer which ones *aren't* installed.
$notInstalled = Compare-Object $modules $installed -PassThru

if ($notInstalled) { # At least one module is missing.

  # Prompt for installing the missing ones.
  $promptText = @"
  The following modules aren't currently installed:
  
      $notInstalled
  
  Would you like to install them now?
"@
  
  
  if ($choice -ne 0) { Write-Warning 'Aborted.'; exit 1 }
  
  # Install the missing modules now.
  Install-Module $notInstalled -Scope CurrentUser -AllowClobber -Force
}

Import-module $modules


$RequiredScopes = @("DeviceManagementApps.ReadWrite.All", "User.ReadWrite.All","Application.ReadWrite.All", "Group.ReadWrite.All", "Policy.ReadWrite.ConditionalAccess", "DeviceManagementConfiguration.ReadWrite.All", "DeviceManagementServiceConfig.ReadWrite.All","Directory.Read.All","Directory.ReadWrite.All","RoleManagement.Read.Directory","RoleManagement.ReadWrite.Directory", "UserAuthenticationMethod.ReadWrite.All","Policy.ReadWrite.Authorization","EntitlementManagement.ReadWrite.All")

Connect-MgGraph -Scopes $RequiredScopes


$StandardCAGroups= @(
    "SG365_Exclude_CA002: Default Block - Travel Users Exclusion"
    "SG365_Exclude_CA004: Require multi-factor authentication for allusers_Restricted",
    "SG365_Exclude_CA009.5: Require Intune - Windows Devices_Restricted",
    "SG365_Exclude_CA009.6: Require Intune MacOS_Testing-Only",
    "SG365_Exclude_CA009.7: Require Intune IOS-Android_Testing-Only",
    "SG365_Exclude_CA009.8: Require Intune Linux_Testing-Only",
    "SG365_Exclude_CA009: Require compliant or hybrid Azure AD joined device for admins_Restricted"
    "SG365_Exclude_CA00JJ01: Block MFA Enrollment off prem"
    "SG365_Exclude_CA00JJ03: Default Block - Travel Users Exclusion"
)
ForEach ($Group in $StandardCAGroups){
   # check if group exists
   $GroupCheck = Get-MgGroup -Filter "displayName eq '$group'"
   #$GroupCheck = get-mggroup -Property Displayname | Where-Object DisplayName eq $($Group) 
  
   #if not exists then create it
   If(!$GroupCheck){
      $params = @{
         Description = "standard CA exclusion group"
         DisplayName = "$Group"
         GroupTypes = @(
            "Unified"
         )
         MailEnabled = $false
         MailNickname = (Get-Random)
         SecurityEnabled = $true
      }
      New-MgGroup -BodyParameter $params
        Write-Host "$_ was created"
    }else{
        Write-Host "Skipped $_ Already Exists"
 }
}


$Domain = (get-MgDomain | where-Object -Property ID -like "*.onMicrosoft.com").id

$BreakGlassAccounts =@(
"zEmergencyAdmin"
"zEmergencyAdmin2"
)


ForEach ($user in $BreakGlassAccounts){
 # check if User exists
 $UserCheck = Get-MgUser -Filter "displayName eq '$User'"
 #$UserCheck = get-mgUser -Property Displayname | Where-Object DisplayName eq $($User)
 #if not exists then create it
 If(!$UserCheck){
     #Create Password for Account
     $PasswordProfile = @{
         Password = Read-Host 'Paste 150 Charecter Password from Passportal for' $User -AsSecureString
     }
     New-MgUser -DisplayName "$user" -PasswordProfile $PasswordProfile `
     -AccountEnabled -MailNickName "$user" `
     -UserPrincipalName ($user + "@" + $domain)
     }
 else{
    Write-host "$_ Already Exists"
 }
}

write-output "Users are being created, please wait 20 seconds"
Start-Sleep -Seconds 20


write-host "Assiging Authentication Methods"
$Z1 = (get-mguser | Where-Object -Property UserPrincipalName -CMatch zEmergencyAdmin).id 

forEach ($ID in $Z1){
    New-MgUserAuthenticationEmailMethod -UserId $ID -EmailAddress "theadmins@pathforwardit.com"
    $params = @{
        "@odata.type" = "#microsoft.graph.unifiedRoleAssignment"
        RoleDefinitionId = "62e90394-69f5-4237-9190-012177145e10"
        PrincipalId = "$ID"
        DirectoryScopeId = "/"
    }
    New-MgRoleManagementDirectoryRoleAssignment -BodyParameter $params
}

$params = @{
	allowExternalIdentitiesToLeave = $true
}
Update-MgPolicyExternalIdentityPolicy -BodyParameter $params

$params = @{
	guestUserRoleId = "2af84b1e-32c8-42b7-82bc-daa82404023b"
	allowInvitesFrom = "adminsAndGuestInviters"
}

Update-MgPolicyAuthorizationPolicy -BodyParameter $params

$params = @{
	selfServiceSignUp = @{
		isEnabled = $false
	}
}
Update-MgPolicyAuthenticationFlowPolicy -BodyParameter $params

#Create Named Locations for Conditional Access 
$CountryNameLocations =@(
    "Allowed Countries"
    "Travel Countries"
)

foreach($Location in $CountryNameLocations){

$namedLocation = Get-MgIdentityConditionalAccessNamedLocation -Filter "DisplayName eq '$Location'"
if ($null -eq $namedLocation) {
    $body = @{
        "@odata.type" = "#microsoft.graph.countryNamedLocation" 
        DisplayName = $Location 
        CountriesAndRegions = @("US") 
        IncludeUnknownCountriesAndRegions = $false 
    }
    $namedLocation = New-MgIdentityConditionalAccessNamedLocation -BodyParameter $body
    Write-Host "Created named location $Location."
} else {
    Write-Host "Skipped named location $location because it already exists."
}
}

###################   Admin MFA Policy ############
$params = @{
    DisplayName = "CA001: Require multi-factor authentication for admins"
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
          "e8611ab8-c189-46e8-94e1-60213ab1f814"
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
     GrantControls = @{
       Operator = "OR"
       BuiltInControls = @(
         "mfa"
       )
     }
  }
  
  New-MgIdentityConditionalAccessPolicy -BodyParameter $params


  
###################   Default Block Policy ########
$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA002: Default Block - Travel Exclusion')" | Select-Object ID
$AllowedCountriesNamedLocation = Get-MgIdentityConditionalAccessNamedLocation -Filter "startswith(DisplayName,Allowed Countries')" | Select-Object ID

$params = @{
  DisplayName = "CA002: Default Block"
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
        $ExcludeCAGroups.id
       )
    }
    Locations = @{
      IncludeLocations = @(
        "All"
      )
      ExcludeLocations =@(
        "AllTrusted"
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

New-MgIdentityConditionalAccessPolicy -BodyParameter $params

################### Block Legacy Auth Policy ######
$params = @{
    DisplayName = "CA003: Block legacy authentication"
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
  
  New-MgIdentityConditionalAccessPolicy -BodyParameter $params


################### MFA for All Users Policy #######
$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA004: Require multi-factor authentication for allusers_Restricted')" | Select-Object ID

$params = @{
  DisplayName = "CA004: Require multi-factor authentication for all users"
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
   GrantControls = @{
     Operator = "OR"
     BuiltInControls = @(
       "mfa"
     )
   }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params


################### MFA for Guest Users Policy ######
$params = @{
    DisplayName = "CA005: Require multi-factor authentication for guest access"
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
         "mfa"
       )
     }
  }
  
  New-MgIdentityConditionalAccessPolicy -BodyParameter $params


################### MFA for Azure Management Policy ############
$params = @{
    DisplayName = "CA006: Require multi-factor authentication for Azure management"
    State = "disabled"
    Conditions = @{
      ClientAppTypes = @(
        "browser", 
        "mobileAppsAndDesktopClients"
      )
      Applications = @{
        IncludeApplications = @(
          "797f4846-ba00-4fd7-ba43-dac1f8f63013"
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
         "mfa"
       )
     }
  }
  
  New-MgIdentityConditionalAccessPolicy -BodyParameter $params


################### Reuire Compliance Device Admins ############
$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'CA009: Require compliant or hybrid Azure AD joined device for admins')" | Select-Object ID


$params = @{
  DisplayName = "CA009: Require compliant or hybrid Azure AD joined device for admins"
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
      ExcludeUsers =@(
        $ExcludeCAGroups.Id
      )
      IncludeRoles =@(
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
        "a9ea8996-122f-4c74-9520-8edcd192826c"
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
      "compliantDevice",
      "domainJoinedDevice"
     )
   }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params


################### Require Compliant Device Windwos ###########

$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA009.5: Require Intune - Windows Devices_Restricted')" | Select-Object ID


$params = @{
  DisplayName = "CA009.5: Require Intune - Windows Devices"
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

New-MgIdentityConditionalAccessPolicy -BodyParameter $params

################### Require Compliant Device MacOS   ###########
$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA009.6: Require Intune MacOS_Testing-Only')" | Select-Object ID

$params = @{
  DisplayName = "CA009.6 Require Intune MacOS"
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
        "macOS"
      )
    }
    users = @{
      IncludeUsers = @(
        "All"
       )
      ExcludeUsers =@(
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

New-MgIdentityConditionalAccessPolicy -BodyParameter $params

################### Require Compliant Device Policy IOS/ Andriod #############
$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA009.7: Require Intune IOS-Android_Testing-Only')" | Select-Object ID

$params = @{
  DisplayName = "CA009.7: Require Intune IOS-Android"
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
        "android",
        "iOS"
      )
    }
    users = @{
      IncludeUsers = @(
        "All"
       )
      ExcludeUsers =@(
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

New-MgIdentityConditionalAccessPolicy -BodyParameter $params


################### Require App Protection Policy IOS/Andriod ################
$params = @{
    DisplayName = "CA009.7.2: Require Intune Mobile Device App Protection Policy"
    State = "disabled"
    Conditions = @{
      ClientAppTypes = @(
        "All"
      )
      Applications = @{
        IncludeApplications = @(
          "browser", 
          "mobileAppsAndDesktopClients"
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
  
  New-MgIdentityConditionalAccessPolicy -BodyParameter $params


################### Block Unsupported Platforms ##############################
$params = @{
    DisplayName = "CA010: Block access for unknown or unsupported device platform"
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
      Platforms =@{
        IncludePlatforms =@(
          "All"
        )
        ExcludePlayforms =@(
          "android",
          "iOS",
          "windows",
          "macOS"
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
       Operator = "AND"
       BuiltInControls = @(
        "Block"
       )
     }
  }
  
  New-MgIdentityConditionalAccessPolicy -BodyParameter $params


################### Block MFA Enrollment Off Prem Policy #######################
$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA00JJ01: Block MFA Enrollment off prem')" | Select-Object ID

$params = @{
  DisplayName = "CAJJ001: Block MFA Reistratoin off Prem"
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
       ExcludeUsers =@(
        $ExcludeCAGroups.ID
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

New-MgIdentityConditionalAccessPolicy -BodyParameter $params

#################### Encrtytion Allow for External Users Policy ############
$params = @{
    DisplayName = "CAJJ002: Email Encryption External User Access"
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
  
  New-MgIdentityConditionalAccessPolicy -BodyParameter $params


#################### Default Block - Travel Policy ##############
$ExcludeCAGroups = Get-MgGroup -top 999 -Filter "startswith(DisplayName,'SG365_Exclude_CA002: Default Block - Travel Exclusion')" | Select-Object ID
$TravelCountriesNamedLocation = Get-MgIdentityConditionalAccessNamedLocation -Filter "startswith(DisplayName,'Travel Countries')" | Select-Object ID
$AllowedCountriesNamedLocation = Get-MgIdentityConditionalAccessNamedLocation -Filter "startswith(DisplayName,Allowed Countries')" | Select-Object ID

$params = @{
  DisplayName = "CAJJ003: Default Block - Travel Policy"
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
        $ExcludeCAGroups.Id
       )
    }
    Locations = @{
      IncludeLocations = @(
        "All"
      )
      ExcludeLocations =@(
        $AllowedCountriesNamedLocation.id
        $TravelCountriesNamedLocation.id
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

New-MgIdentityConditionalAccessPolicy -BodyParameter $params

Disconnect-Graph


###########################################################################################################################
#Deploy Microsoft Teams Settings


Connect-MicrosoftTeams 
 
# Turn off Guest Access by Default - Allow as needed
#Set-CsTeamsClientConfiguration -Identity Global -AllowGuestUser $false 

#Set Teams External Access - Block By Default and allow as needed
#Set-CsTenantFederationConfiguration -AllowFederatedUsers $False -AllowTeamsConsumer $False -AllowTeamsConsumerInbound $False -AllowPublicUsers $False


# Set Teams Meeting Lobby Policy
Set-CsTeamsMeetingPolicy -Identity Global -AllowAnonymousUsersToJoinMeeting $true -AutoAdmittedUsers "EveryoneInCompanyExcludingGuests" -AllowAnonymousUsersToStartMeeting $false -AllowPSTNUsersToBypassLobby $false


# Block all Apps in Teams except for PowerBI
$SharepointApp = New-Object -TypeName Microsoft.Teams.Policy.Administration.Cmdlets.Core.DefaultCatalogApp -Property @{Id="2a527703-1f6f-4559-a332-d8a7d288cd88"}
$PowerBIApp = New-Object -TypeName Microsoft.Teams.Policy.Administration.Cmdlets.Core.DefaultCatalogApp -Property @{Id="1c4340de-2a85-40e5-8eb0-4f295368978b"}
$DefaultCatalogAppList = @($SharepointApp,$PowerBIApp)
Set-CsTeamsAppPermissionPolicy -Identity "Global" -DefaultCatalogAppsType AllowedAppList  -DefaultCatalogApps $DefaultCatalogAppList -GlobalCatalogAppsType AllowedAppList -GlobalCatalogApps @() -PrivateCatalogAppsType AllowedAppList -PrivateCatalogApps @()

# Turn off all 3r Party Cloud Storage
Set-CsTeamsClientConfiguration -Identity Global -AllowDropBox $false -AllowEgnyte $false -AllowGoogleDrive $false -AllowBox $false --AllowShareFile $false


Disconnect-MicrosoftTeams

###########################################################################################################################################
#Exchange online 

Connect-ExchangeOnline

Enable-OrganizationCustomization
$licenseUrl = (Get-AadrmConfiguration).LicensingIntranetDistributionPointUrl
    
Set-IRMConfiguration -LicensingLocation @{add=$licenseUrl} -InternalLicensingEnabled $true -AutomaticServiceUpdateEnabled $true -EnablePdfEncryption $true -SimplifiedClientAccessEnabled $true -DecryptAttachmentForEncryptOnly $true -AzureRMSLicensingEnabled $true


New-RemoteDomain -Name PathForward -DomainName pathforwardit.com -AutoReplyEnabled $true -AutoForwardEnabled $true -AllowedOOFType External
