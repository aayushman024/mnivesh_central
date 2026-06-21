# ============================================================
# mnivesh_central — Phase 3: Rewrite Imports
# Converts all internal relative imports to package: imports
# ============================================================

$lib  = "lib"
$pkg  = "mnivesh_central"

# Each row: OldFragment (appears inside an import string) => NewPackagePath
$map = [ordered]@{
    # core/api
    "API/api_client.dart"          = "package:$pkg/core/api/api_client.dart"
    "API/api_config.dart"          = "package:$pkg/core/api/api_config.dart"
    "API/api_service.dart"         = "package:$pkg/core/api/api_service.dart"

    # core/services
    "Services/analytics_service.dart"                     = "package:$pkg/core/services/analytics_service.dart"
    "Services/app_tokens_service.dart"                    = "package:$pkg/core/services/app_tokens_service.dart"
    "Services/bootstrap_service.dart"                     = "package:$pkg/core/services/bootstrap_service.dart"
    "Services/cache_service.dart"                         = "package:$pkg/core/services/cache_service.dart"
    "Services/connectivity_service.dart"                  = "package:$pkg/core/services/connectivity_service.dart"
    "Services/CustomHapticService.dart"                   = "package:$pkg/core/services/custom_haptic_service.dart"
    "Services/download_service.dart"                      = "package:$pkg/core/services/download_service.dart"
    "Services/fcm_service.dart"                           = "package:$pkg/core/services/fcm_service.dart"
    "Services/FirebasePerformanceNetworkInterceptor.dart"  = "package:$pkg/core/services/firebase_performance_network_interceptor.dart"
    "Services/permission_helper.dart"                     = "package:$pkg/core/services/permission_helper.dart"
    "Services/snackBar_Service.dart"                      = "package:$pkg/core/services/snack_bar_service.dart"
    "Services/sync_service.dart"                          = "package:$pkg/core/services/sync_service.dart"
    "Services/updater_service.dart"                       = "package:$pkg/core/services/updater_service.dart"
    "Services/location_sharing_service.dart"              = "package:$pkg/features/daftar/services/location_sharing_service.dart"
    "Services/module_usage_service.dart"                  = "package:$pkg/features/modules_analytics/services/module_usage_service.dart"

    # core/providers
    "Providers/profile_image_provider.dart"  = "package:$pkg/core/providers/profile_image_provider.dart"
    "Providers/location_provider.dart"        = "package:$pkg/features/daftar/providers/location_provider.dart"
    "Providers/module_usage_provider.dart"    = "package:$pkg/features/modules_analytics/providers/module_usage_provider.dart"
    "Providers/app_provider.dart"             = "package:$pkg/features/app_store/providers/app_provider.dart"
    "Providers/download_state_provider.dart"  = "package:$pkg/features/app_store/providers/download_state_provider.dart"

    # core/theme
    "Themes/AppTextStyle.dart"  = "package:$pkg/core/theme/app_text_style.dart"
    "Themes/AppTheme.dart"      = "package:$pkg/core/theme/app_theme.dart"

    # core/utils
    "Utils/Dimensions.dart"           = "package:$pkg/core/utils/dimensions.dart"
    "Utils/DiscardChangesDialog.dart"  = "package:$pkg/core/utils/discard_changes_dialog.dart"
    "Utils/DismissKeyboard.dart"       = "package:$pkg/core/utils/dismiss_keyboard.dart"
    "Utils/CallynCardHelper.dart"      = "package:$pkg/features/callyn_analytics/widgets/callyn_card_helper.dart"
    "Utils/CallynDateHelper.dart"      = "package:$pkg/features/callyn_analytics/widgets/callyn_date_helper.dart"
    "Utils/marketing_image_util.dart"  = "package:$pkg/features/marketing/utils/marketing_image_util.dart"
    "Utils/route_visit_image_util.dart" = "package:$pkg/features/route_management/utils/route_visit_image_util.dart"
    "Utils/ModuleTransitionAnimation.dart" = "package:$pkg/features/modules/utils/module_transition_animation.dart"

    # features/auth
    "Managers/AuthManager.dart"                          = "package:$pkg/features/auth/managers/auth_manager.dart"
    "Managers/AuthWrapper.dart"                          = "package:$pkg/features/auth/managers/auth_wrapper.dart"
    "Managers/ChildSsoRequestHandler.dart"               = "package:$pkg/features/auth/managers/child_sso_request_handler.dart"
    "ViewModels/login_viewModel.dart"                    = "package:$pkg/features/auth/view_models/login_view_model.dart"

    # features/home
    "ViewModels/announcement_viewModel.dart"             = "package:$pkg/features/announcements/view_models/announcement_view_model.dart"
    "Models/announcement.dart"                           = "package:$pkg/features/announcements/models/announcement.dart"

    # features/daftar
    "ViewModels/attendance_viewModel.dart"               = "package:$pkg/features/daftar/view_models/attendance_view_model.dart"
    "ViewModels/leave_viewModel.dart"                    = "package:$pkg/features/daftar/view_models/leave_view_model.dart"
    "API/attendance_apiService.dart"                     = "package:$pkg/features/daftar/api/attendance_api_service.dart"
    "Models/attendance_shiftLog.dart"                    = "package:$pkg/features/daftar/models/attendance_shift_log.dart"

    # features/team_status
    "ViewModels/teamStatus_viewModel.dart"               = "package:$pkg/features/team_status/view_models/team_status_view_model.dart"
    "Models/userDetailsModel.dart"                       = "package:$pkg/features/team_status/models/user_details_model.dart"

    # features/callyn_analytics
    "ViewModels/callynAnalytics_viewModel.dart"          = "package:$pkg/features/callyn_analytics/view_models/callyn_analytics_view_model.dart"
    "API/callyn_apiService.dart"                         = "package:$pkg/features/callyn_analytics/api/callyn_api_service.dart"
    "Models/callyn_analytics_model.dart"                 = "package:$pkg/features/callyn_analytics/models/callyn_analytics_model.dart"

    # features/modules_analytics
    "ViewModels/modules_analytics_viewModel.dart"        = "package:$pkg/features/modules_analytics/view_models/modules_analytics_view_model.dart"
    "API/analytics_api_service.dart"                     = "package:$pkg/features/modules_analytics/api/analytics_api_service.dart"
    "Models/modules_analytics_model.dart"                = "package:$pkg/features/modules_analytics/models/modules_analytics_model.dart"

    # features/marketing
    "ViewModels/marketing_viewModel.dart"                = "package:$pkg/features/marketing/view_models/marketing_view_model.dart"
    "API/marketing_api_service.dart"                     = "package:$pkg/features/marketing/api/marketing_api_service.dart"
    "Models/marketing_model.dart"                        = "package:$pkg/features/marketing/models/marketing_model.dart"

    # features/operations + mf_transaction
    "API/operations_apiService.dart"                     = "package:$pkg/features/operations/api/operations_api_service.dart"
    "ViewModels/mfTransForm_viewModel.dart"              = "package:$pkg/features/operations/mf_transaction/view_models/mf_trans_form_view_model.dart"
    "ViewModels/mfTransaction_viewModel.dart"            = "package:$pkg/features/operations/mf_transaction/view_models/mf_transaction_view_model.dart"
    "Models/mftrans_models.dart"                         = "package:$pkg/features/operations/mf_transaction/models/mf_trans_models.dart"

    # features/investwell_report
    "ViewModels/investwellReport_viewModel.dart"         = "package:$pkg/features/investwell_report/view_models/investwell_report_view_model.dart"
    "Models/investwell_report_models.dart"               = "package:$pkg/features/investwell_report/models/investwell_report_models.dart"

    # features/route_management
    "ViewModels/routeOptimization_viewModel.dart"        = "package:$pkg/features/route_management/view_models/route_optimization_view_model.dart"
    "API/route_optimization_api_service.dart"            = "package:$pkg/features/route_management/api/route_optimization_api_service.dart"
    "Models/route_optimization_models.dart"              = "package:$pkg/features/route_management/models/route_optimization_models.dart"

    # features/app_store
    "ViewModels/appCard_viewModel.dart"                  = "package:$pkg/features/app_store/view_models/app_card_view_model.dart"
    "Models/appModel.dart"                               = "package:$pkg/features/app_store/models/app_model.dart"

    # features/modules
    "Models/moduleScreen_data.dart"                      = "package:$pkg/features/modules/models/module_screen_data.dart"
}

# Screen/widget imports — these typically appear as relative paths in other screens
# We match the filename fragment since they had unique names
$screenWidgetMap = [ordered]@{
    "LoginScreen.dart"                          = "package:$pkg/features/auth/screens/login_screen.dart"
    "HomeScreen.dart"                           = "package:$pkg/features/home/screens/home_screen.dart"
    "MainScreen.dart"                           = "package:$pkg/features/home/screens/main_screen.dart"
    "AnnouncementModalScreen.dart"              = "package:$pkg/features/announcements/screens/announcement_modal_screen.dart"
    "AttendanceScreen.dart"                     = "package:$pkg/features/daftar/screens/attendance_screen.dart"
    "LeaveManagementScreen.dart"                = "package:$pkg/features/daftar/screens/leave_management_screen.dart"
    "TeamStatusScreen.dart"                     = "package:$pkg/features/team_status/screens/team_status_screen.dart"
    "CallynAnalyticsScreen.dart"                = "package:$pkg/features/callyn_analytics/screens/callyn_analytics_screen.dart"
    "ModulesAnalyticsScreen.dart"               = "package:$pkg/features/modules_analytics/screens/modules_analytics_screen.dart"
    "MarketingScreen.dart"                      = "package:$pkg/features/marketing/screens/marketing_screen.dart"
    "MFTransScreen.dart"                        = "package:$pkg/features/operations/mf_transaction/screens/mf_trans_screen.dart"
    "MFTransFormScreen.dart"                    = "package:$pkg/features/operations/mf_transaction/screens/mf_trans_form_screen.dart"
    "MFTransReviewScreen.dart"                  = "package:$pkg/features/operations/mf_transaction/screens/mf_trans_review_screen.dart"
    "MFTransCompletedScreen.dart"               = "package:$pkg/features/operations/mf_transaction/screens/mf_trans_completed_screen.dart"
    "InvestwellReportScreen.dart"               = "package:$pkg/features/investwell_report/screens/investwell_report_screen.dart"
    "RouteManagementDashboardScreen.dart"       = "package:$pkg/features/route_management/screens/route_management_dashboard_screen.dart"
    "add_task_screen.dart"                      = "package:$pkg/features/route_management/screens/add_task_screen.dart"
    "field_executive_tracking_screen.dart"      = "package:$pkg/features/route_management/screens/field_executive_tracking_screen.dart"
    "view_route_details_screen.dart"            = "package:$pkg/features/route_management/screens/view_route_details_screen.dart"
    "visit_details_screen.dart"                 = "package:$pkg/features/route_management/screens/visit_details_screen.dart"
    "StoreScreen.dart"                          = "package:$pkg/features/app_store/screens/store_screen.dart"
    "ModuleScreen.dart"                         = "package:$pkg/features/modules/screens/module_screen.dart"

    # Widgets
    "sso_authorization_bottom_sheet.dart"       = "package:$pkg/features/auth/widgets/sso_authorization_bottom_sheet.dart"
    "AnnouncementsBanner.dart"                  = "package:$pkg/features/home/widgets/announcements_banner.dart"
    "bottomNavBar.dart"                         = "package:$pkg/features/home/widgets/bottom_nav_bar.dart"
    "homeAppBar.dart"                           = "package:$pkg/features/home/widgets/home_app_bar.dart"
    "home_drawer.dart"                          = "package:$pkg/features/home/widgets/home_drawer.dart"
    "QuickActionsSection.dart"                  = "package:$pkg/features/home/widgets/quick_actions_section.dart"
    "CompactPunchCard.dart"                     = "package:$pkg/features/daftar/widgets/compact_punch_card.dart"
    "LocationRow.dart"                          = "package:$pkg/features/daftar/widgets/location_row.dart"
    "PunchButton.dart"                          = "package:$pkg/features/daftar/widgets/punch_button.dart"
    "PunchCard.dart"                            = "package:$pkg/features/daftar/widgets/punch_card.dart"
    "PunchStat.dart"                            = "package:$pkg/features/daftar/widgets/punch_stat.dart"
    "TeamAttendanceSection.dart"                = "package:$pkg/features/daftar/widgets/team_attendance_section.dart"
    "TimerDisplay.dart"                         = "package:$pkg/features/daftar/widgets/timer_display.dart"
    "WorkScheduleSection.dart"                  = "package:$pkg/features/daftar/widgets/work_schedule_section.dart"
    "LeaveCard.dart"                            = "package:$pkg/features/daftar/widgets/leaves/leave_card.dart"
    "LeaveFAB.dart"                             = "package:$pkg/features/daftar/widgets/leaves/leave_fab.dart"
    "LeaveFormComponents.dart"                  = "package:$pkg/features/daftar/widgets/leaves/leave_form_components.dart"
    "LeaveOptionsBottomSheet.dart"              = "package:$pkg/features/daftar/widgets/leaves/leave_options_bottom_sheet.dart"
    "OtherLeaveForm.dart"                       = "package:$pkg/features/daftar/widgets/leaves/other_leave_form.dart"
    "ShortLeaveForm.dart"                       = "package:$pkg/features/daftar/widgets/leaves/short_leave_form.dart"
    "AnalyticsSkeleton.dart"                    = "package:$pkg/features/callyn_analytics/widgets/analytics_skeleton.dart"
    "CallTypeDoughnut.dart"                     = "package:$pkg/features/callyn_analytics/widgets/call_type_doughnut.dart"
    "EmployeeDropdown.dart"                     = "package:$pkg/features/callyn_analytics/widgets/employee_dropdown.dart"
    "ExpandableListCard.dart"                   = "package:$pkg/features/callyn_analytics/widgets/expandable_list_card.dart"
    "FilterTabs.dart"                           = "package:$pkg/features/callyn_analytics/widgets/filter_tabs.dart"
    "HorizontalBarGraph.dart"                   = "package:$pkg/features/callyn_analytics/widgets/horizontal_bar_graph.dart"
    "Pills.dart"                                = "package:$pkg/features/callyn_analytics/widgets/pills.dart"
    "SingleEmployeeSummary.dart"                = "package:$pkg/features/callyn_analytics/widgets/single_employee_summary.dart"
    "AsyncButtons.dart"                         = "package:$pkg/features/marketing/widgets/async_buttons.dart"
    "SwitchForm.dart"                           = "package:$pkg/features/operations/mf_transaction/widgets/switch_form.dart"
    "SystematicForm.dart"                       = "package:$pkg/features/operations/mf_transaction/widgets/systematic_form.dart"
    "UccCard.dart"                              = "package:$pkg/features/operations/mf_transaction/widgets/ucc_card.dart"
    "formComponents.dart"                       = "package:$pkg/features/operations/mf_transaction/widgets/form_components.dart"
    "mfTrans_common_widgets.dart"               = "package:$pkg/features/operations/mf_transaction/widgets/mf_trans_common_widgets.dart"
    "purchRedemptionForm.dart"                  = "package:$pkg/features/operations/mf_transaction/widgets/purch_redemption_form.dart"
    "edit_task_bottom_sheet.dart"               = "package:$pkg/features/route_management/widgets/edit_task_bottom_sheet.dart"
    "modern_visit_card.dart"                    = "package:$pkg/features/route_management/widgets/modern_visit_card.dart"
    "ModuleAppBar.dart"                         = "package:$pkg/features/route_management/widgets/module_app_bar.dart"
    "visit_cards.dart"                          = "package:$pkg/features/route_management/widgets/visit_cards.dart"
    "visit_details_components.dart"             = "package:$pkg/features/route_management/widgets/visit_details_components.dart"
    "visit_image_gallery_viewer.dart"           = "package:$pkg/features/route_management/widgets/visit_image_gallery_viewer.dart"
    "appCard.dart"                              = "package:$pkg/features/app_store/widgets/app_card.dart"
    "download_button.dart"                      = "package:$pkg/features/app_store/widgets/download_button.dart"
    "api_error_state_view.dart"                 = "package:$pkg/features/modules/widgets/api_error_state_view.dart"
}

# Merge both maps
foreach ($k in $screenWidgetMap.Keys) { $map[$k] = $screenWidgetMap[$k] }

$dartFiles = Get-ChildItem -Path $lib -Recurse -Filter "*.dart"
Write-Host "Processing $($dartFiles.Count) dart files..." -ForegroundColor Cyan

$updatedCount = 0

foreach ($file in $dartFiles) {
    $lines = Get-Content $file.FullName -Encoding UTF8
    $changed = $false
    $newLines = foreach ($line in $lines) {
        # Only process import lines
        if ($line -match '^[\s]*import[\s]+[''"]') {
            $newLine = $line
            foreach ($key in $map.Keys) {
                if ($newLine -match [regex]::Escape($key)) {
                    # Replace the entire quoted path with the new package path
                    $newLine = $newLine -replace ("'[^']*" + [regex]::Escape($key) + "[^']*'"), ("'" + $map[$key] + "'")
                    $newLine = $newLine -replace ('"[^"]*' + [regex]::Escape($key) + '[^"]*"'), ('"' + $map[$key] + '"')
                    $changed = $true
                    break
                }
            }
            $newLine
        } else {
            $line
        }
    }
    if ($changed) {
        Set-Content -Path $file.FullName -Value $newLines -Encoding UTF8
        $updatedCount++
        Write-Host "  [UPDATED] $($file.Name)" -ForegroundColor Green
    }
}

Write-Host ('Import rewrite complete - ' + $updatedCount + ' files updated.') -ForegroundColor Cyan

# Phase 4: Remove empty old dirs
Write-Host '=== PHASE 4: Remove old directories ===' -ForegroundColor Cyan
$oldDirs = @('API','Managers','Models','Providers','Services','Themes','Utils','ViewModels','Views')
foreach ($d in $oldDirs) {
    $path = Join-Path $lib $d
    if (Test-Path $path) {
        $remaining = Get-ChildItem $path -Recurse -File
        if ($remaining.Count -eq 0) {
            Remove-Item $path -Recurse -Force
            Write-Host ('  [DELETED] ' + $d + '/') -ForegroundColor Green
        } else {
            Write-Host ('  [WARN] ' + $d + '/ still has ' + $remaining.Count + ' file(s):') -ForegroundColor Yellow
            $remaining | ForEach-Object { Write-Host ('    ' + $_.FullName) -ForegroundColor Yellow }
        }
    } else {
        Write-Host ('  [ALREADY GONE] ' + $d + '/') -ForegroundColor Gray
    }
}

Write-Host '=== Done! Now run: flutter analyze ===' -ForegroundColor Cyan

