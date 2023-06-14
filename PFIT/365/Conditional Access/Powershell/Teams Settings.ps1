# Check if Microsoft Graph module is installed
if (-not (Get-Module -Name MicrosoftTeams -ListAvailable)) {
    # Install Microsoft Graph module
    Install-Module -Name MicrosoftTeams -Force -AllowClobber -Scope CurrentUser
    
    # Import Microsoft Graph module
    Import-Module -Name MicrosoftTeams 

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



# Turn off all 3r Party Cloud Storage
Set-CsTeamsClientConfiguration -Identity Global -AllowDropBox $false -AllowEgnyte $false -AllowGoogleDrive $false -AllowBox $false --AllowShareFile $false


Manage apps > Org wide settings

Third party off
Custom Off 