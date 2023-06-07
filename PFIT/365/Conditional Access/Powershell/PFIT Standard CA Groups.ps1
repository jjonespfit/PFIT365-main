$StandardCAGroups= @(
         "SG365_Exclude_CA004: Require multi-factor authentication for allusers_Restricted",
         "SG365_Exclude_CA009.5: Require Intune - Windows Devices_Restricted",
         "SG365_Exclude_CA009.6: Require Intune MacOS_Testing-Only",
         "SG365_Exclude_CA009.7: Require Intune IOS-Android_Testing-Only",
         "SG365_Exclude_CA009.8: Require Intune Linux_Testing-Only",
         "SG365_Exclude_CA009: Require compliant or hybrid Azure AD joined device for admins_Restricted"
)

$RequiredScopes = @("DeviceManagementApps.ReadWrite.All", "User.ReadWrite.All","Application.ReadWrite.All", "Group.ReadWrite.All", "Policy.ReadWrite.ConditionalAccess", "DeviceManagementConfiguration.ReadWrite.All", "DeviceManagementServiceConfig.ReadWrite.All","Directory.Read.All","Directory.ReadWrite.All","RoleManagement.Read.Directory","RoleManagement.ReadWrite.Directory", "UserAuthenticationMethod.ReadWrite.All")

Connect-MgGraph -Scopes $RequiredScopes
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
   }else{
      Write-Output "$_ Already Exists"
   }
}

New-MgUser