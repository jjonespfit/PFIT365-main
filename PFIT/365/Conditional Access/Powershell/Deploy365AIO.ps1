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
  $choice = $host.UI.PromptForChoice('Missing modules', $promptText, ('&Yes', '&No'), 0)
  
  if ($choice -ne 0) { Write-Warning 'Aborted.'; exit 1 }
  
  # Install the missing modules now.
  Install-Module $notInstalled -Scope CurrentUser -AllowClobber -Force
}

Import-module $modules

$credential = Get-Credential
$RequiredScopes = @("DeviceManagementApps.ReadWrite.All", "User.ReadWrite.All","Application.ReadWrite.All", "Group.ReadWrite.All", "Policy.ReadWrite.ConditionalAccess", "DeviceManagementConfiguration.ReadWrite.All", "DeviceManagementServiceConfig.ReadWrite.All","Directory.Read.All","Directory.ReadWrite.All","RoleManagement.Read.Directory","RoleManagement.ReadWrite.Directory", "UserAuthenticationMethod.ReadWrite.All","Policy.ReadWrite.Authorization","EntitlementManagement.ReadWrite.All")

Connect-MgGraph -Credential $credential -Scopes $RequiredScopes


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

Disconnect-Graph







Connect-MicrosoftTeams -Credential $credential
 
# Turn off Guest Access by Default - Allow as needed
Set-CsTeamsClientConfiguration -Identity Global -AllowGuestUser $false 

#Set Teams External Access - Block By Default and allow as needed
Set-CsTenantFederationConfiguration -AllowFederatedUsers $False -AllowTeamsConsumer $False -AllowTeamsConsumerInbound $False -AllowPublicUsers $False


# Set Teams Meeting Lobby Policy
Set-CsTeamsMeetingPolicy -Identity Global -AllowAnonymousUsersToJoinMeeting $true -AutoAdmittedUsers "EveryoneInCompanyExcludingGuests" -AllowAnonymousUsersToStartMeeting $false -AllowPSTNUsersToBypassLobby $false
People dialing in can bypass the lobby
Who can bypass the lobby

# Block all Apps in Teams except for PowerBI
$PowweBIApp = New-Object -TypeName Microsoft.Teams.Policy.Administration.Cmdlets.Core.DefaultCatalogApp -Property @{Id="1c4340de-2a85-40e5-8eb0-4f295368978b"}
$DefaultCatalogAppList = @($SharepointApp,$PowweBIApp)
Set-CsTeamsAppPermissionPolicy -Identity "Global" -DefaultCatalogAppsType AllowedAppList  -DefaultCatalogApps $DefaultCatalogAppList -GlobalCatalogAppsType AllowedAppList -GlobalCatalogApps @() -PrivateCatalogAppsType AllowedAppList -PrivateCatalogApps @()

Disconnect-MicrosoftTeams


