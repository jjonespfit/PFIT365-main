Install-Module AIPservice
connect-aipservice
Enable-AIPService


Import-Module ExchangeOnline
Connect-ExchangeOnline
$licenseUrl = (Get-AadrmConfiguration).LicensingIntranetDistributionPointUrl
    
Set-IRMConfiguration -LicensingLocation @{add=$licenseUrl} -InternalLicensingEnabled $true -AutomaticServiceUpdateEnabled $true -EnablePdfEncryption $true -SimplifiedClientAccessEnabled $true -DecryptAttachmentForEncryptOnly $true -AzureRMSLicensingEnabled $true
    
Enable-OrganizationCustomization

        $LBL = "RU","ZH-CN","ZH-TW","JA","KO","HE","LV","AR","FR","Vi","PT"
        $RBL = "AX","BY","BR","BI","CF","CN","CG","CD","CI","HR","CU","CZ","DJ","DM","DO","EC","EG","SV","GQ","ER","EE","ET","FK","FO","FJ","GF","PF","TF","GA","GM","GE","GH","GL","GD","GP","GU","GT","GG","GN","GW","GY","HT","HM","HN","HK","HU","IN","ID","IR","IQ","IM","IL","JM","SJ","XJ","JP","JE","JO","KZ","KE","KI","KR","KW","KG","LA","LV","LB","LS","LR","LY","LI","LT","MO","MG","MW","MY","MV","ML","MT","MH","MQ","MR","MU","YT","FM","MD","MC","MN","ME","MS","MA","MZ","MM","NA","NR","NP","NC","NZ","NI","NE","NG","NU","NF","KP","MK","MP","OM","PK","PW","PS","PA","PG","PY","PE","PH","PN","PL","PT","PR","QA","RE","RO","RU","RW","XS","BL","KN","LC","MF","PM","VC","WS","SM","ST","SA","SN","RS","SC","SL","SG","XE","SX","SK","SI","SB","SO","ZA","GS","ES","LK","SH","SD","SR","SZ","SY","TW","TJ","TZ","TH","TL","TG","TK","TO","TT","TN","TR","TM","TC","TV","UM","VI","UG","UA","AE","UY","UZ","VU","VE","VN","WF","YE","ZM","ZW"
        $domains = Get-AcceptedDomain | Where-Object{$_.DomainType -eq 'Authoritative'}
    
    ## Set ATP Policy to standards
    Set-AtpPolicyForO365 -Identity "Default" -EnableATPForSPOTeamsODB $true -EnableSafeDocs $false -AllowSafeDocsOpen $false
    
    ## Set Hosted Content Filter Policy to standards
    Set-HostedContentFilterPolicy -Identity "Default" -IncreaseScoreWithImageLinks On -IncreaseScoreWithNumericIps On -IncreaseScoreWithRedirectToOtherPort On -IncreaseScoreWithBizOrInfoUrls On -MarkAsSpamEmptyMessages On -MarkAsSpamSensitiveWordList On -MarkAsSpamSpfRecordHardFail On -MarkAsSpamFromAddressAuthFail On -MarkAsSpamBulkMail On -MarkAsSpamNdrBackscatter On -HighConfidenceSpamAction Quarantine -SpamAction MoveToJmf -DownloadLink $false -BulkThreshold 5 -InlineSafetyTips $true -BulkSpamAction Quarantine -PhishSpamAction MoveToJmf -SpamZapEnabled $true -PhishZapEnabled $true -HighConfidencePhishAction Quarantine -EnableRegionBlockList $true -EnableLanguageBlockList $true -RegionBlockList $RBL -LanguageBlockList $LBL
    
    ## Set Malware Filter Policy to standards
    Set-MalwareFilterPolicy -Identity "Default" -InternalSenderAdminAddress cwp1@caltech.com -EnableInternalSenderAdminNotifications $true -EnableFileFilter $true -ZapEnabled $true
    
    ## Set Hosted Outbound Spam Filter Policy to standards
    Set-HostedOutboundSpamFilterPolicy -Identity "Default" -AutoForwardingMode On
    
    ## Set Hosted Connection Filter Policy to standards
    Set-HostedConnectionFilterPolicy -Identity "Default" -EnableSafeList $true
    
    ## Set Safe Attachment Policy to standards
    New-SafeAttachmentPolicy -Name "Default SA Policy" -Redirect $false -Action DynamicDelivery -Enable $true -ActionOnError $false 
    
    ##Set Safe Attachments Rule
    New-SafeAttachmentRule -Name "Default SA Rule" -SafeAttachmentPolicy "Default SA Policy" -RecipientDomainIs $domains.domainname
    
    ##SafeLinks Policy
    New-SafeLinksPolicy -Name "Default SL Policy" -EnableSafeLinksforEmail $true -EnableSafeLinksForTeams $true -ScanUrls $true -EnableOrganizationBranding $true -DeliverMessageAfterScan $true -EnableForInternalSenders $true -AllowClickThrough $false -TrackClicks $true
    
    ##SafeLinks Rule
    New-SafeLinksRule -Name "Default SL Rule" -SafeLinksPolicy "Default SL Policy" -RecipientDomainIs $domains.domainname

    ##Anti-Phish Policy
    Set-AntiPhishPolicy -Identity "Office365 AntiPhish Default" -PhishThresholdLevel 3 -EnableMailboxIntelligenceProtection $true -EnableOrganizationDomainsProtection $true -EnableMailboxIntelligence $true -EnableSimilarDomainsSafetyTips $true -EnableFirstContactSafetyTips $true -EnableUnusualCharactersSafetyTips $true -EnableSpoofIntelligence $true -EnableViaTag $true -EnableUnauthenticatedSender $true -MailboxIntelligenceProtectionAction MovetoJmf -TargetedDomainProtectionAction MovetoJmf -AuthenticationFailAction MovetoJmf
    
Connect-IPPSSession

    $CCSI = @(@{Name="International Classification of Diseases (ICD-9-CM)"; maxcount="-1"; confidencelevel="High"; mincount="1"},@{Name="International Classification of Diseases (ICD-10-CM)"; maxcount="-1"; confidencelevel="High"; mincount="1"},@{Name="All Medical Terms And Conditions"; maxcount="-1"; confidencelevel="High"; mincount="1"},@{Name="U.S. Physical Addresses"; maxcount="-1"; confidencelevel="Medium"; mincount="1"})
    $params = @{
        'Name' = 'PFIT Standard Encryption Policy';
        'ExchangeLocation' = 'All';
        'Mode' = 'Enable'
        }

    $HIPAARuleValue = @{
        'Name' = 'U.S. Health Insurance Act (HIPAA) Enhanced';
        'EncryptRMSTemplate' = 'Encrypt';
        'Policy' = 'PFIT Standard Encryption Policy';
        'ReportSeverityLevel' = 'Low';
        'ContentContainsSensitiveInformation' = $CCSI;
        'AccessScope' = 'NotInOrganization';
        'Disabled' = $true;
    }
    New-Label -Name "Manual Encryption" -DisplayName "Manual Encryption" -Tooltip "Use this label to manually encrypt email" `
    -EncryptionContentExpiredOnDateInDaysOrNever "Never" -EncryptionOfflineAccessDays "-1" -ContentType "File, Email" -EncryptionDoNotForward $false `
    -EncryptionEnabled $true -EncryptionEncryptOnly $true `
    -EncryptionRightsDefinitions "AuthenticatedUsers:View,ViewRightsData,DOCEDIT,EDIT,PRINT,EXTRACT,REPLY,REPLYALL,FORWARD,OBJMODEL"

    New-LabelPolicy -Name "Manual Encryption" -Labels "Manual Encryption" -ExchangeLocation "All"

    $ManualCCSI = @(@{Operator="And"; Groups=@(@{Name="Default"; Operator="Or"; labels=@(@{Name="Manual Encryption";type="Sensitivity"})})})
    $ManualRuleValue = @{
        'Name' = 'Manually Encrypted';
        'EncryptRMSTemplate' = 'Encrypt';
        'Policy' = 'PFIT Standard Encryption Policy';
        'ReportSeverityLevel' = 'Low';
        'ContentContainsSensitiveInformation' = $ManualCCSI;
        'AccessScope' = 'NotInOrganization';
        'Disabled'=$true;
    }
    new-dlpcompliancepolicy @params

    new-dlpcompliancerule @ManualRuleValue

    new-dlpcompliancerule $HIPAARuleValue

Disconnect-ExchangeOnline


PII Enhanced for Teams 

Discuss Prompt in Teams as needed