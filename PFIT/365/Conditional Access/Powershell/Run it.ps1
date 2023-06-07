$RequiredScopes = @("DeviceManagementApps.ReadWrite.All", "User.ReadWrite.All","Application.ReadWrite.All", "Group.ReadWrite.All", "Policy.ReadWrite.ConditionalAccess", "DeviceManagementConfiguration.ReadWrite.All", "DeviceManagementServiceConfig.ReadWrite.All","Directory.Read.All","Directory.ReadWrite.All","RoleManagement.Read.Directory","RoleManagement.ReadWrite.Directory", "UserAuthenticationMethod.ReadWrite.All")

Connect-MgGraph -Scopes $RequiredScopes
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
    Write-Output "$_ Already Exists"
 }
}

Start-Sleep -Seconds 10
write-host "Users are being created"

$Z1 = (get-mguser | Where-Object -Property UserPrincipalName -CMatch zEmergencyAdmin).id 

forEach ($ID in $Z1){
    New-MgUserAuthenticationEmailMethod -UserId $ID -EmailAddress "theadmins@pathforwardit.com"
}
write-host "Assiging Authentication Methods"
Disconnect-Graph









 
