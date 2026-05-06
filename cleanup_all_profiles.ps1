$profilesPath = "c:\Users\shubham.yadav_infobe\Desktop\ALL Migration\ALL Migratation\force-app\main\default\profiles"
$profiles = @(
    "Admin Clone.profile-meta.xml",
    "BrokerPortal Profile.profile-meta.xml",
    "BrokerPortalView Profile.profile-meta.xml",
    "Customer Community User.profile-meta.xml",
    "CustomerCommunity Profile.profile-meta.xml",
    "RealEstate Profile.profile-meta.xml",
    "RealEstatePortal Profile.profile-meta.xml",
    "Tele Caller.profile-meta.xml",
    "ThankYouPage Profile.profile-meta.xml"
)

$invalidTabs = @(
    "standard-AccountInsight",
    "standard-ActionCadence",
    "standard-Audience360",
    "standard-B2bEmail",
    "standard-BenefitPeriod",
    "standard-BranchService",
    "standard-BranchServiceDetail",
    "standard-Business",
    "standard-BusinessBranch",
    "standard-Calibration",
    "standard-Campaign",
    "standard-CampaignInfluence",
    "standard-Case",
    "standard-CaseArticle",
    "standard-Channel",
    "standard-ChannelProgramLevel",
    "standard-Coaching",
    "standard-ColumnMetric",
    "standard-CommSubscription",
    "standard-CommunityUsersPage",
    "standard-Contact",
    "standard-ContactFeedback",
    "standard-ContentAdmin",
    "standard-Contract",
    "standard-DataQueryWorkspace",
    "standard-DataServices",
    "standard-DealAllocation",
    "standard-DesktopFlow",
    "standard-DomainSite",
    "standard-DueDate",
    "standard-Event",
    "standard-ExperienceCloud",
    "standard-ExternalAccount",
    "standard-ExternalSalesUser",
    "standard-ExternalUser",
    "standard-FAQ",
    "standard-FieldService",
    "standard-ForecastingSettings",
    "standard-ForecastingType",
    "standard-GoalV2",
    "standard-GrantedByLicense",
    "standard-Greeting",
    "standard-Grid",
    "standard-GuestUser",
    "standard-HeroPage",
    "standard-HighVelocitySales",
    "standard-HighVelocitySalesSettings",
    "standard-HomePageComponent",
    "standard-ImageFile",
    "standard-Initiative",
    "standard-InitiativeLink",
    "standard-InsurancePolicy",
    "standard-InsurancePolicyAsset",
    "standard-IntegrationHub",
    "standard-IntegrationHubApi",
    "standard-IntegrationHubPublishedFlow",
    "standard-IntegrationHubScheduledFlow",
    "standard-InternalSalesUser",
    "standard-InternalUser",
    "standard-IpRange",
    "standard-IpRangeRule",
    "standard-KnowledgeArticle",
    "standard-Metric",
    "standard-SecurityCenterClassification",
    "standard-Sites",
    "standard-UserDevopsPreference",
    "standard-WorkFeedbackRequest",
    "standard-WorkPerformanceCycle",
    "standard-WorkRewardFund",
    "standard-WorkRewardFundType"
)

foreach ($profile in $profiles) {
    $filePath = Join-Path $profilesPath $profile
    
    if (-not (Test-Path $filePath)) {
        Write-Host "File not found: $filePath"
        continue
    }
    
    Write-Host "Cleaning: $profile"
    
    $content = Get-Content -Path $filePath -Raw
    
    $content = $content -replace '(?s)<applicationVisibilities>\s*<application>TwilioFlexCTI__Flex_CTI</application>\s*<default>false</default>\s*<visible>false</visible>\s*</applicationVisibilities>', ''
    $content = $content -replace '(?s)<applicationVisibilities>\s*<application>ZVC__Zoom_Admin_for_Lightning</application>\s*<default>false</default>\s*<visible>false</visible>\s*</applicationVisibilities>', ''
    $content = $content -replace '(?s)<applicationVisibilities>\s*<application>gupshup_crm__Gupshup</application>\s*<default>false</default>\s*<visible>false</visible>\s*</applicationVisibilities>', ''
    $content = $content -replace '(?s)<applicationVisibilities>\s*<application>gupshup_crm__Gupshup</application>\s*<default>false</default>\s*<visible>true</visible>\s*</applicationVisibilities>', ''
    $content = $content -replace '(?s)<applicationVisibilities>\s*<application>nativevideocmpt__NativeVideo_Free</application>\s*<default>false</default>\s*<visible>false</visible>\s*</applicationVisibilities>', ''
    $content = $content -replace '(?s)<applicationVisibilities>\s*<application>nativevideocmpt__NativeVideo_Free</application>\s*<default>false</default>\s*<visible>true</visible>\s*</applicationVisibilities>', ''
    $content = $content -replace '(?s)<applicationVisibilities>\s*<application>tdc_tsw__SMS360</application>\s*<default>false</default>\s*<visible>false</visible>\s*</applicationVisibilities>', ''
    $content = $content -replace '(?s)<applicationVisibilities>\s*<application>tdc_tsw__SMS360_Lightning</application>\s*<default>false</default>\s*<visible>false</visible>\s*</applicationVisibilities>', ''
    $content = $content -replace '(?s)<applicationVisibilities>\s*<application>standard__DataGovernanceConsole</application>\s*<default>false</default>\s*<visible>false</visible>\s*</applicationVisibilities>', ''
    $content = $content -replace '(?s)<applicationVisibilities>\s*<application>standard__DataGovernanceConsole</application>\s*<default>false</default>\s*<visible>true</visible>\s*</applicationVisibilities>', ''
    
    # Remove standard__Sites application visibility block
    $content = $content -replace '(?s)<applicationVisibilities>\s*<application>standard__Sites</application>\s*<default>false</default>\s*<visible>false</visible>\s*</applicationVisibilities>\s*', ''
    $content = $content -replace '(?s)<applicationVisibilities>\s*<application>standard__Sites</application>\s*<default>false</default>\s*<visible>true</visible>\s*</applicationVisibilities>\s*', ''
    
    $content = $content -replace '(?s)<classAccesses>\s*<apexClass>gupshup_crm__[^<]*</apexClass>\s*<enabled>(?:true|false)</enabled>\s*</classAccesses>\s*', ''
    $content = $content -replace '(?s)<classAccesses>\s*<apexClass>TwilioFlexCTI__[^<]*</apexClass>\s*<enabled>(?:true|false)</enabled>\s*</classAccesses>\s*', ''
    $content = $content -replace '(?s)<classAccesses>\s*<apexClass>ZVC__[^<]*</apexClass>\s*<enabled>(?:true|false)</enabled>\s*</classAccesses>\s*', ''
    $content = $content -replace '(?s)<classAccesses>\s*<apexClass>nativevideocmpt__[^<]*</apexClass>\s*<enabled>(?:true|false)</enabled>\s*</classAccesses>\s*', ''
    $content = $content -replace '(?s)<classAccesses>\s*<apexClass>tdc_tsw__[^<]*</apexClass>\s*<enabled>(?:true|false)</enabled>\s*</classAccesses>\s*', ''
    $content = $content -replace '(?s)<classAccesses>\s*<apexClass>lmCTI__[^<]*</apexClass>\s*<enabled>(?:true|false)</enabled>\s*</classAccesses>\s*', ''
    $content = $content -replace '(?s)<classAccesses>\s*<apexClass>tdc_tsw__[^<]*</apexClass>\s*<enabled>(?:true|false)</enabled>\s*</classAccesses>\s*', ''
    
    $content = $content -replace '(?s)<customSettingAccesses>\s*<enabled>(?:true|false)</enabled>\s*<name>gupshup_crm__[^<]*</name>\s*</customSettingAccesses>\s*', ''
    
    $content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>[^<]*ZVC__[^<]*</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''
    $content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>[^<]*TDC__[^<]*</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''
    $content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>[^<]*gupshup_crm__[^<]*</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''
    $content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>[^<]*TwilioFlexCTI__[^<]*</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''
    $content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>[^<]*nativevideocmpt__[^<]*</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''
    $content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>[^<]*tdc_tsw__[^<]*</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''
    
    # Remove DandbCompanyId field permissions (field doesn't exist)
    $content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>Account\.DandbCompanyId</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''
    $content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>Lead\.DandbCompanyId</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''
    
    # Remove DunsNumber field permissions (field doesn't exist in target org)
    $content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>Account\.DunsNumber</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''
    $content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>Lead\.CompanyDunsNumber</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''
    
    # Remove NaicsCode field permissions (field doesn't exist in target org)
    $content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>Account\.NaicsCode</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''
    
    # Remove NaicsDesc field permissions (field doesn't exist in target org)
    $content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>Account\.NaicsDesc</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''
    
    # Remove Tradestyle field permissions (field doesn't exist in target org)
    $content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>Account\.Tradestyle</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''
    
    # Remove YearStarted field permissions (field doesn't exist in target org)
    $content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>Account\.YearStarted</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''
    
    # Remove Product2.SellerId field permissions (field doesn't exist in target org)
    $content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>Product2\.SellerId</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''
    
    # Remove Product2.SourceProductId field permissions (field doesn't exist in target org)
    $content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>Product2\.SourceProductId</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''
    
    # Remove DandBCompany layout assignments
    $content = $content -replace '(?s)<layoutAssignments>\s*<layout>DandBCompany[^<]*</layout>\s*<recordType>[^<]*</recordType>\s*</layoutAssignments>\s*', ''
    $content = $content -replace '(?s)<layoutAssignments>\s*<layout>DandBCompany[^<]*</layout>\s*</layoutAssignments>\s*', ''
    
    # Remove DandBCompany tab visibility
    $content = $content -replace '(?s)<tabVisibilities>\s*<tab>standard-DandBCompany</tab>\s*<visibility>[^<]*</visibility>\s*</tabVisibilities>\s*', ''
    
    $content = $content -replace '(?s)<pageAccesses>\s*<apexPage>gupshup_crm__[^<]*</apexPage>\s*<enabled>(?:true|false)</enabled>\s*</pageAccesses>\s*', ''
    $content = $content -replace '(?s)<pageAccesses>\s*<apexPage>ZVC__[^<]*</apexPage>\s*<enabled>(?:true|false)</enabled>\s*</pageAccesses>\s*', ''
    $content = $content -replace '(?s)<pageAccesses>\s*<apexPage>nativevideocmpt__[^<]*</apexPage>\s*<enabled>(?:true|false)</enabled>\s*</pageAccesses>\s*', ''
    $content = $content -replace '(?s)<pageAccesses>\s*<apexPage>tdc_tsw__[^<]*</apexPage>\s*<enabled>(?:true|false)</enabled>\s*</pageAccesses>\s*', ''
    $content = $content -replace '(?s)<pageAccesses>\s*<apexPage>lmCTI__[^<]*</apexPage>\s*<enabled>(?:true|false)</enabled>\s*</pageAccesses>\s*', ''
    
    $content = $content -replace '(?s)<tabVisibilities>\s*<tab>gupshup_crm__[^<]*</tab>\s*<visibility>[^<]*</visibility>\s*</tabVisibilities>\s*', ''
    $content = $content -replace '(?s)<tabVisibilities>\s*<tab>TwilioFlexCTI__[^<]*</tab>\s*<visibility>[^<]*</visibility>\s*</tabVisibilities>\s*', ''
    $content = $content -replace '(?s)<tabVisibilities>\s*<tab>ZVC__[^<]*</tab>\s*<visibility>[^<]*</visibility>\s*</tabVisibilities>\s*', ''
    $content = $content -replace '(?s)<tabVisibilities>\s*<tab>nativevideocmpt__[^<]*</tab>\s*<visibility>[^<]*</visibility>\s*</tabVisibilities>\s*', ''
    $content = $content -replace '(?s)<tabVisibilities>\s*<tab>tdc_tsw__[^<]*</tab>\s*<visibility>[^<]*</visibility>\s*</tabVisibilities>\s*', ''
    
    $content = $content -replace '(?s)<flowAccesses>\s*<enabled>(?:true|false)</enabled>\s*<flow>gupshup_crm__[^<]*</flow>\s*</flowAccesses>\s*', ''
    $content = $content -replace '(?s)<flowAccesses>\s*<enabled>(?:true|false)</enabled>\s*<flowName>gupshup_crm__[^<]*</flowName>\s*</flowAccesses>\s*', ''
    $content = $content -replace '(?s)<flowAccesses>\s*<enabled>(?:true|false)</enabled>\s*<flow>TwilioFlexCTI__[^<]*</flow>\s*</flowAccesses>\s*', ''
    $content = $content -replace '(?s)<flowAccesses>\s*<enabled>(?:true|false)</enabled>\s*<flowName>TwilioFlexCTI__[^<]*</flowName>\s*</flowAccesses>\s*', ''
    $content = $content -replace '(?s)<flowAccesses>\s*<enabled>(?:true|false)</enabled>\s*<flow>nativevideocmpt__[^<]*</flow>\s*</flowAccesses>\s*', ''
    $content = $content -replace '(?s)<flowAccesses>\s*<enabled>(?:true|false)</enabled>\s*<flowName>nativevideocmpt__[^<]*</flowName>\s*</flowAccesses>\s*', ''
    $content = $content -replace '(?s)<flowAccesses>\s*<enabled>(?:true|false)</enabled>\s*<flow>tdc_tsw__[^<]*</flow>\s*</flowAccesses>\s*', ''
    $content = $content -replace '(?s)<flowAccesses>\s*<enabled>(?:true|false)</enabled>\s*<flowName>tdc_tsw__[^<]*</flowName>\s*</flowAccesses>\s*', ''
    
    $content = $content -replace '(?s)<layoutAssignments>\s*<layout>[^<]*gupshup_crm__[^<]*</layout>\s*<recordType>[^<]*</recordType>\s*</layoutAssignments>\s*', ''
    $content = $content -replace '(?s)<layoutAssignments>\s*<layout>[^<]*TwilioFlexCTI__[^<]*</layout>\s*<recordType>[^<]*</recordType>\s*</layoutAssignments>\s*', ''
    $content = $content -replace '(?s)<layoutAssignments>\s*<layout>[^<]*nativevideocmpt__[^<]*</layout>\s*<recordType>[^<]*</recordType>\s*</layoutAssignments>\s*', ''
    $content = $content -replace '(?s)<layoutAssignments>\s*<layout>[^<]*tdc_tsw__[^<]*</layout>\s*<recordType>[^<]*</recordType>\s*</layoutAssignments>\s*', ''
    
    $content = $content -replace '(?s)<layoutAssignments>\s*<layout>[^<]*gupshup_crm__[^<]*</layout>\s*</layoutAssignments>\s*', ''
    $content = $content -replace '(?s)<layoutAssignments>\s*<layout>[^<]*TwilioFlexCTI__[^<]*</layout>\s*</layoutAssignments>\s*', ''
    $content = $content -replace '(?s)<layoutAssignments>\s*<layout>[^<]*ZVC__[^<]*</layout>\s*</layoutAssignments>\s*', ''
    $content = $content -replace '(?s)<layoutAssignments>\s*<layout>[^<]*nativevideocmpt__[^<]*</layout>\s*</layoutAssignments>\s*', ''
    $content = $content -replace '(?s)<layoutAssignments>\s*<layout>[^<]*tdc_tsw__[^<]*</layout>\s*</layoutAssignments>\s*', ''
    
    foreach ($tab in $invalidTabs) {
        $pattern = [regex]::Escape($tab)
        $content = $content -replace "(?s)<tabVisibilities>\s*<tab>$pattern</tab>\s*<visibility>[^<]*</visibility>\s*</tabVisibilities>\s*", ''
    }
    
    $content = $content -replace "(\r\n){3,}", "`r`n`r`n"
    
    Set-Content -Path $filePath -Value $content -Encoding UTF8
    Write-Host ("Cleaned: " + $profile)
}

Write-Host "All profiles cleaned successfully!"
