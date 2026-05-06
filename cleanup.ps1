$filePath = 'force-app\main\default\profiles\Tele Caller.profile-meta.xml'
$content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)

# Remove TwilioFlexCTI application visibility block
$content = $content -replace '(?s)<applicationVisibilities>\s*<application>TwilioFlexCTI__Flex_CTI</application>\s*<default>false</default>\s*<visible>false</visible>\s*</applicationVisibilities>', ''

# Remove gupshup application visibility block
$content = $content -replace '(?s)<applicationVisibilities>\s*<application>gupshup_crm__Gupshup</application>\s*<default>false</default>\s*<visible>true</visible>\s*</applicationVisibilities>', ''

# Remove nativevideocmpt application visibility block
$content = $content -replace '(?s)<applicationVisibilities>\s*<application>nativevideocmpt__NativeVideo_Free</application>\s*<default>false</default>\s*<visible>true</visible>\s*</applicationVisibilities>', ''

# Remove gupshup classAccesses blocks
$content = $content -replace '(?s)<classAccesses>\s*<apexClass>gupshup_crm__[^<]*</apexClass>\s*<enabled>(?:true|false)</enabled>\s*</classAccesses>\s*', ''

# Remove TwilioFlexCTI classAccesses blocks
$content = $content -replace '(?s)<classAccesses>\s*<apexClass>TwilioFlexCTI__[^<]*</apexClass>\s*<enabled>(?:true|false)</enabled>\s*</classAccesses>\s*', ''

# Remove nativevideocmpt classAccesses blocks
$content = $content -replace '(?s)<classAccesses>\s*<apexClass>nativevideocmpt__[^<]*</apexClass>\s*<enabled>(?:true|false)</enabled>\s*</classAccesses>\s*', ''

# Remove gupshup customSettingAccesses blocks
$content = $content -replace '(?s)<customSettingAccesses>\s*<enabled>(?:true|false)</enabled>\s*<name>gupshup_crm__[^<]*</name>\s*</customSettingAccesses>\s*', ''

# Remove ZVC__ field permissions
$content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>[^<]*\.ZVC__[^<]*</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''

# Remove TDC__ field permissions  
$content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>[^<]*\.TDC__[^<]*</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''

# Remove gupshup_crm__ field permissions
$content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>[^<]*gupshup_crm__[^<]*</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''

# Remove TwilioFlexCTI__ field permissions
$content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>[^<]*TwilioFlexCTI__[^<]*</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''

# Remove nativevideocmpt__ field permissions
$content = $content -replace '(?s)<fieldPermissions>\s*<editable>(?:true|false)</editable>\s*<field>[^<]*nativevideocmpt__[^<]*</field>\s*<readable>(?:true|false)</readable>\s*</fieldPermissions>\s*', ''

# Remove gupshup flow references
$content = $content -replace '(?s)<flowAccesses>\s*<enabled>(?:true|false)</enabled>\s*<flow>gupshup_crm__[^<]*</flow>\s*</flowAccesses>\s*', ''

# Remove nativevideocmpt flow references
$content = $content -replace '(?s)<flowAccesses>\s*<enabled>(?:true|false)</enabled>\s*<flow>nativevideocmpt__[^<]*</flow>\s*</flowAccesses>\s*', ''

# Remove ZVC__ layout references
$content = $content -replace '(?s)<layoutAssignments>\s*<layout>[^<]*ZVC__[^<]*</layout>\s*</layoutAssignments>\s*', ''

# Remove gupshup layout references
$content = $content -replace '(?s)<layoutAssignments>\s*<layout>[^<]*gupshup_crm__[^<]*</layout>\s*</layoutAssignments>\s*', ''

# Remove TwilioFlexCTI layout references
$content = $content -replace '(?s)<layoutAssignments>\s*<layout>[^<]*TwilioFlexCTI__[^<]*</layout>\s*</layoutAssignments>\s*', ''

# Remove nativevideocmpt layout references
$content = $content -replace '(?s)<layoutAssignments>\s*<layout>[^<]*nativevideocmpt__[^<]*</layout>\s*</layoutAssignments>\s*', ''

# Remove gupshup apex page references
$content = $content -replace '(?s)<pageAccesses>\s*<apexPage>gupshup_crm__[^<]*</apexPage>\s*<enabled>(?:true|false)</enabled>\s*</pageAccesses>\s*', ''

# Remove nativevideocmpt apex page references
$content = $content -replace '(?s)<pageAccesses>\s*<apexPage>nativevideocmpt__[^<]*</apexPage>\s*<enabled>(?:true|false)</enabled>\s*</pageAccesses>\s*', ''

# Remove gupshup tab visibility references
$content = $content -replace '(?s)<tabVisibilities>\s*<tab>gupshup_crm__[^<]*</tab>\s*<visibility>[^<]*</visibility>\s*</tabVisibilities>\s*', ''

# Remove TwilioFlexCTI tab visibility references
$content = $content -replace '(?s)<tabVisibilities>\s*<tab>TwilioFlexCTI__[^<]*</tab>\s*<visibility>[^<]*</visibility>\s*</tabVisibilities>\s*', ''

# Remove nativevideocmpt tab visibility references
$content = $content -replace '(?s)<tabVisibilities>\s*<tab>nativevideocmpt__[^<]*</tab>\s*<visibility>[^<]*</visibility>\s*</tabVisibilities>\s*', ''

# Remove invalid/unsupported standard tabs
$invalidTabs = @(
    'AccountInsight', 'Audience360', 'B2bEmail', 'B2bSocialSearch', 'C360ProfileSearch', 'Calibration',
    'CallTemplate', 'ClaimAdjuster', 'Coaching', 'ContactSuggestionInsight', 'DataMgmtPolicy', 'DataQueryWorkspace',
    'DelegatedAccount', 'EinsteinAssistant', 'EngagementProgram', 'EnhancedEmailTemplate', 'SemanticModel', 'ForecastingLightning',
    'Goal', 'GoalV2', 'HvsWaveLightning', 'LandingPageContent', 'LearningItem', 'Metric', 'News', 'OpportunityContactRoleSuggestionInsight',
    'OpportunityInsight', 'OrgManagement', 'ProfilePlatformCoaching', 'ProfilePlatformFeedback', 'ProfilePlatformGoals', 'SalesCoachHome',
    'SecurityCenterClassification', 'SecurityCenterCustomMetrics', 'SecurityCenterNotification', 'SecurityCenterPolicies', 'SecurityHealthCheck',
    'SecurityHub', 'ServiceAppointmentGroup', 'ServiceTerritoryRelationship', 'Sites', 'Snippet', 'UserDevopsPreference', 'WaveHomeLightningEacFree',
    'WorkFeedbackRequest', 'WorkPerformanceCycle', 'WorkProcedure', 'WorkProcedureStep', 'WorkQueue', 'WorkRewardFund', 'WorkRewardFundType',
    'WorkTypeExtension', 'ActionCadence'
)

foreach ($tab in $invalidTabs) {
    $content = $content -replace "(?s)<tabVisibilities>\s*<tab>standard-$tab</tab>\s*<visibility>[^<]*</visibility>\s*</tabVisibilities>\s*", ''
}

# Clean up extra blank lines
$content = $content -replace "`n\s*`n\s*`n+", "`n`n"

[System.IO.File]::WriteAllText($filePath, $content, [System.Text.Encoding]::UTF8)
Write-Host "Cleanup completed successfully!"
