$RequiredScopes = @("DeviceManagementApps.ReadWrite.All", "User.ReadWrite.All","Application.ReadWrite.All", "Group.ReadWrite.All", "Policy.ReadWrite.ConditionalAccess", "DeviceManagementConfiguration.ReadWrite.All", "DeviceManagementServiceConfig.ReadWrite.All","Directory.Read.All","Directory.ReadWrite.All","RoleManagement.Read.Directory","RoleManagement.ReadWrite.Directory", "UserAuthenticationMethod.ReadWrite.All")

Connect-MgGraph -Scopes $RequiredScopes
function Set-PFITMgDeviceAppManagementMobileApp {
    Param(
        [Parameter(Mandatory = $true)] [ValidateSet('Android', 'iOS')] [string] $Platform,
        [Parameter(Mandatory = $true)] [string] $Name,
        [Parameter(Mandatory = $false)] [string] $AppStoreUrl
    )

    Process {
        $mobileApp = Get-MgDeviceAppManagementMobileApp `
            -Filter "isof('microsoft.graph.$($Platform)StoreApp')" `
            | Where-Object DisplayName -eq "$Name"
        if ($null -eq $mobileApp) {
            if ($Platform -eq 'Android') {
                $minimumSupportedVersion = @{ "v10_0" = $true };
            } else {
                $appStoreApp = Invoke-RestMethod `
                    -Uri "https://itunes.apple.com/search?country=us&media=software&entity=software,iPadSoftware&term=$Name" `
                    | ForEach-Object { $_.results[0] }
                $appStoreIcon = Invoke-WebRequest `
                    -Uri $appStoreApp.artworkUrl512 `
                    | ForEach-Object { [System.Convert]::ToBase64String($_.Content) }
                $applicableDeviceType = @{
                    "iPad" = $true;
                    "iPhoneAndIPod" = $true;
                };
                $appStoreUrl = $appStoreApp.trackViewUrl;
                $description = $appStoreApp.description;
                $minimumSupportedVersion = @{ "v14_0" = $true };
                $publisher = $appStoreApp.artistName;
                $settings = @{
                    "@odata.type" = "#microsoft.graph.$($Platform)StoreAppAssignmentSettings";
                    "uninstallOnDeviceRemoval" = $false
                };
            }

            $body = @{
                "@odata.type" = "#microsoft.graph.$($Platform)StoreApp";
                "applicableDeviceType" = $applicableDeviceType;
                "appStoreUrl" = $appStoreUrl;
                "description" = $description;
                "displayName" = $Name;
                "largeIcon" = @{
                    "type" = "image/jpeg";
                    "value" = $appStoreIcon;
                };
                "minimumSupportedOperatingSystem" = $minimumSupportedVersion;
                "publisher" = $publisher;
            } | ConvertTo-Json
            $mobileApp = New-MgDeviceAppManagementMobileApp -BodyParameter $body
            $mobileApp = Get-MgDeviceAppManagementMobileApp -MobileAppId $mobileApp.Id
            while ($mobileApp.PublishingState -eq 'processing') {
                $mobileApp = Get-MgDeviceAppManagementMobileApp -MobileAppId $mobileApp.Id
                Start-Sleep 1
            }

            $body = @{
                "mobileAppAssignments" = @(
                    @{
                        "@odata.type" = "#microsoft.graph.mobileAppAssignment";
                        "target" = @{
                            "@odata.type" = "#microsoft.graph.allLicensedUsersAssignmentTarget";
                        };
                        "intent" = "AvailableWithoutEnrollment";
                        "settings" = $settings;
                    }
                );
            } | ConvertTo-Json -Depth 3
            Invoke-GraphRequest `
                -Method POST `
                -Uri "https://graph.microsoft.com/beta/deviceAppManagement/mobileApps/$($mobileApp.Id)/assign" `
                -Body $body
            Write-Host "Created $Platform mobile app $Name."
        } else {
            Write-Host "Skipped $Platform mobile app $Name because it already exists."
        }

        return $mobileApp
    }
}

function Set-PFITDeviceAppManagementAndroidManagedAppProtection {
    Param(
        [Parameter(Mandatory = $true)] [string] $Name,
        [Parameter(Mandatory = $true)] [string[]] $PackageIds
    )
    
    Process {
        $allusers = get-mggroup -All | Where-object {$_.DisplayName -eq "All Users"}
        $managedAppProtection = Get-MgDeviceAppManagementAndroidManagedAppProtection -Filter "DisplayName eq '$Name'"
        if ($null -eq $managedAppProtection) {
            $body = @{
                "@odata.type" = "#microsoft.graph.androidManagedAppProtection";
                "apps" = $PackageIds | ForEach-Object {
                    @{
                        "mobileAppIdentifier" = @{
                            "@odata.type" = "#microsoft.graph.androidMobileAppIdentifier";
                            "packageId" = $_;
                        };
                    }
                };
                "allowedDataStorageLocations" = @("oneDriveForBusiness");
                "allowedOutboundClipboardSharingLevel" = "managedAppsWithPasteIn";
                "allowedOutboundDataTransferDestinations" = "managedApps";
                "assignments" = @(
                    @{
                        "target" = @{
                            "@odata.type" = "#microsoft.graph.groupAssignmentTarget";
                            "groupId" = $allusers.id; # All Users
                        };
                    }
                );
                "dataBackupBlocked" = $true;
                "deviceComplianceRequired" = $true;
                "displayName" = $Name;
                "encryptAppData" = $true;
                "periodOfflineBeforeAccessCheck" = "PT12H";
                "periodOfflineBeforeWipeIsEnforced" = "P90D";
                "periodOnlineBeforeAccessCheck" = "PT30M";
                "pinRequired" = $true;
                "minimumPinLength" = "6";
                "saveAsBlocked" = $true;
            } | ConvertTo-Json -Depth 3
            $managedAppProtection = New-MgDeviceAppManagementAndroidManagedAppProtection -BodyParameter $body
            Write-Host "Created Android managed app protection $Name."
        } else {
            Write-Host "Skipped Android managed app protection $Name because it already exists."
        }
    }
}

function Set-PFITDeviceAppManagementiOSManagedAppProtection {
    Param(
        [Parameter(Mandatory = $true)] [string] $Name,
        [Parameter(Mandatory = $true)] [string[]] $BundleIds
    )

    Process {
        $allusers = get-mggroup -All | Where-object {$_.DisplayName -eq "All Users"}
        $managedAppProtection = Get-MgDeviceAppManagementiOSManagedAppProtection -Filter "DisplayName eq '$Name'"
        if ($null -eq $managedAppProtection) {
            $body = @{
                "@odata.type" = "#microsoft.graph.iosManagedAppProtection";
                "apps" = $BundleIds | ForEach-Object {
                    @{
                        "mobileAppIdentifier" = @{
                            "@odata.type" = "#microsoft.graph.iosMobileAppIdentifier";
                            "bundleId" = $_;
                        };
                    }
                };
                "allowedDataStorageLocations" = @("oneDriveForBusiness", "sharePoint");
                "allowedOutboundClipboardSharingLevel" = "managedAppsWithPasteIn";
                "allowedOutboundDataTransferDestinations" = "managedApps";
                "appDataEncryptionType" = "whenDeviceLocked";
                "assignments" = @(
                    @{
                        "target" = @{
                            "@odata.type" = "#microsoft.graph.groupAssignmentTarget";
                            "groupId" = $allusers.id; # All Users
                        };
                    }
                );
                "dataBackupBlocked" = $true;
                "deviceComplianceRequired" = $true;
                "disableAppPinIfDevicePinIsSet" = $true;
                "displayName" = $Name;
                "exemptedAppProtocols" = @();
                "periodOfflineBeforeAccessCheck" = "PT12H";
                "periodOfflineBeforeWipeIsEnforced" = "P90D";
                "periodOnlineBeforeAccessCheck" = "PT5M";
                "pinRequired" = $true;
                "minimumPinLength" = "6";
                "saveAsBlocked" = $true;
            } | ConvertTo-Json -Depth 3
            $managedAppProtection = New-MgDeviceAppManagementiOSManagedAppProtection -BodyParameter $body
            Write-Host "Created iOS managed app protection $Name."
        } else {
            Write-Host "Skipped iOS managed app protection $Name because it already exists."
        }
    }
}
function Set-PFITOneDefenseDeviceAppManagementStandards {
    param(
        
    )
        $bundleIds = @(
        (Set-PFITMgDeviceAppManagementMobileApp "iOS" "Adobe Acrobat Reader"),
        (Set-PFITMgDeviceAppManagementMobileApp "iOS" "Microsoft Authenticator"),
        (Set-PFITMgDeviceAppManagementMobileApp "iOS" "Microsoft Bookings"),
        (Set-PFITMgDeviceAppManagementMobileApp "iOS" "Microsoft Edge"),
        (Set-PFITMgDeviceAppManagementMobileApp "iOS" "Microsoft Excel"),
        (Set-PFITMgDeviceAppManagementMobileApp "iOS" "Microsoft Office"),
        (Set-PFITMgDeviceAppManagementMobileApp "iOS" "Microsoft OneDrive"),
        (Set-PFITMgDeviceAppManagementMobileApp "iOS" "Microsoft OneNote"),
        (Set-PFITMgDeviceAppManagementMobileApp "iOS" "Microsoft Outlook"),
        (Set-PFITMgDeviceAppManagementMobileApp "iOS" "Microsoft PowerPoint"),
        (Set-PFITMgDeviceAppManagementMobileApp "iOS" "Microsoft SharePoint"),
        (Set-PFITMgDeviceAppManagementMobileApp "iOS" "Microsoft Teams"),
        (Set-PFITMgDeviceAppManagementMobileApp "iOS" "Microsoft To Do"),
        (Set-PFITMgDeviceAppManagementMobileApp "iOS" "Microsoft Word")
    ) | ForEach-Object { $_.AdditionalProperties.bundleId }
    Set-PFITDeviceAppManagementiOSManagedAppProtection "Default Mobile App Policy for iOS devices" `
        -BundleIds $bundleIds
    
    $packageIds = @(
        (Set-PFITMgDeviceAppManagementMobileApp "Android" "Adobe Acrobat Reader" `
            -AppStoreUrl "https://play.google.com/store/apps/details?id=com.adobe.reader"),
        (Set-PFITMgDeviceAppManagementMobileApp "Android" "Microsoft Authenticator" `
            -AppStoreUrl "https://play.google.com/store/apps/details?id=com.azure.authenticator"),
        (Set-PFITMgDeviceAppManagementMobileApp "Android" "Microsoft Bookings" `
            -AppStoreUrl "https://play.google.com/store/apps/details?id=com.microsoft.exchange.bookings"),
        (Set-PFITMgDeviceAppManagementMobileApp "Android" "Microsoft Edge" `
            -AppStoreUrl "https://play.google.com/store/apps/details?id=com.microsoft.emmx"),
        (Set-PFITMgDeviceAppManagementMobileApp "Android" "Microsoft Excel" `
            -AppStoreUrl "https://play.google.com/store/apps/details?id=com.microsoft.office.excel"),
        (Set-PFITMgDeviceAppManagementMobileApp "Android" "Microsoft Office" `
            -AppStoreUrl "https://play.google.com/store/apps/details?id=com.microsoft.office.officehubrow"),
        (Set-PFITMgDeviceAppManagementMobileApp "Android" "Microsoft OneDrive" `
            -AppStoreUrl "https://play.google.com/store/apps/details?id=com.microsoft.skydrive"),
        (Set-PFITMgDeviceAppManagementMobileApp "Android" "Microsoft OneNote" `
            -AppStoreUrl "https://play.google.com/store/apps/details?id=com.microsoft.office.onenote"),
        (Set-PFITMgDeviceAppManagementMobileApp "Android" "Microsoft Outlook" `
            -AppStoreUrl "https://play.google.com/store/apps/details?id=com.microsoft.office.outlook"),
        (Set-PFITMgDeviceAppManagementMobileApp "Android" "Microsoft PowerPoint" `
            -AppStoreUrl "https://play.google.com/store/apps/details?id=com.microsoft.office.powerpoint"),
        (Set-PFITMgDeviceAppManagementMobileApp "Android" "Microsoft SharePoint" `
            -AppStoreUrl "https://play.google.com/store/apps/details?id=com.microsoft.sharepoint"),
        (Set-PFITMgDeviceAppManagementMobileApp "Android" "Microsoft Teams" `
            -AppStoreUrl "https://play.google.com/store/apps/details?id=com.microsoft.teams"),
        (Set-PFITMgDeviceAppManagementMobileApp "Android" "Microsoft To Do" `
            -AppStoreUrl "https://play.google.com/store/apps/details?id=com.microsoft.todos"),
        (Set-PFITMgDeviceAppManagementMobileApp "Android" "Microsoft Word" `
            -AppStoreUrl "https://play.google.com/store/apps/details?id=com.microsoft.office.word")
    ) | ForEach-Object { $_.AdditionalProperties.packageId }
    Set-PFITDeviceAppManagementAndroidManagedAppProtection "Default Mobile App Policy for Android devices" `
        -PackageIds $packageIds
    }


Set-PFITOneDefenseDeviceAppManagementStandards

Disconnect-Graph



