# ============================================================
# mnivesh_central — Feature-First Refactor Script
# Run from the project root: .\refactor_to_feature_first.ps1
# ============================================================

$lib = "lib"

# ── helper ──────────────────────────────────────────────────
function Move-Dart {
    param([string]$src, [string]$dst)
    $srcPath = Join-Path $lib $src
    $dstPath = Join-Path $lib $dst
    if (-not (Test-Path $srcPath)) {
        Write-Host "  [SKIP] not found: $srcPath" -ForegroundColor Yellow
        return
    }
    $dstDir = Split-Path $dstPath -Parent
    if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
    Move-Item -Path $srcPath -Destination $dstPath -Force
    Write-Host "  [OK] $src → $dst" -ForegroundColor Green
}

# ============================================================
# PHASE 1 — core/
# ============================================================
Write-Host "`n=== PHASE 1: core/ ===" -ForegroundColor Cyan

# core/api
Move-Dart "API/api_client.dart"          "core/api/api_client.dart"
Move-Dart "API/api_config.dart"          "core/api/api_config.dart"
Move-Dart "API/api_service.dart"         "core/api/api_service.dart"

# core/services
Move-Dart "Services/analytics_service.dart"                        "core/services/analytics_service.dart"
Move-Dart "Services/app_tokens_service.dart"                       "core/services/app_tokens_service.dart"
Move-Dart "Services/bootstrap_service.dart"                        "core/services/bootstrap_service.dart"
Move-Dart "Services/cache_service.dart"                            "core/services/cache_service.dart"
Move-Dart "Services/connectivity_service.dart"                     "core/services/connectivity_service.dart"
Move-Dart "Services/CustomHapticService.dart"                      "core/services/custom_haptic_service.dart"
Move-Dart "Services/download_service.dart"                         "core/services/download_service.dart"
Move-Dart "Services/fcm_service.dart"                              "core/services/fcm_service.dart"
Move-Dart "Services/FirebasePerformanceNetworkInterceptor.dart"    "core/services/firebase_performance_network_interceptor.dart"
Move-Dart "Services/permission_helper.dart"                        "core/services/permission_helper.dart"
Move-Dart "Services/snackBar_Service.dart"                         "core/services/snack_bar_service.dart"
Move-Dart "Services/sync_service.dart"                             "core/services/sync_service.dart"
Move-Dart "Services/updater_service.dart"                          "core/services/updater_service.dart"

# core/providers
Move-Dart "Providers/profile_image_provider.dart"  "core/providers/profile_image_provider.dart"

# core/theme
Move-Dart "Themes/AppTextStyle.dart"  "core/theme/app_text_style.dart"
Move-Dart "Themes/AppTheme.dart"      "core/theme/app_theme.dart"

# core/utils
Move-Dart "Utils/Dimensions.dart"           "core/utils/dimensions.dart"
Move-Dart "Utils/DiscardChangesDialog.dart" "core/utils/discard_changes_dialog.dart"
Move-Dart "Utils/DismissKeyboard.dart"      "core/utils/dismiss_keyboard.dart"

# ============================================================
# PHASE 2 — features/
# ============================================================
Write-Host "`n=== PHASE 2: features/ ===" -ForegroundColor Cyan

# ── auth ────────────────────────────────────────────────────
Move-Dart "Views/Screens/LoginScreen.dart"                       "features/auth/screens/login_screen.dart"
Move-Dart "ViewModels/login_viewModel.dart"                      "features/auth/view_models/login_view_model.dart"
Move-Dart "Managers/AuthManager.dart"                            "features/auth/managers/auth_manager.dart"
Move-Dart "Managers/AuthWrapper.dart"                            "features/auth/managers/auth_wrapper.dart"
Move-Dart "Managers/ChildSsoRequestHandler.dart"                 "features/auth/managers/child_sso_request_handler.dart"
Move-Dart "Views/Widgets/sso_authorization_bottom_sheet.dart"    "features/auth/widgets/sso_authorization_bottom_sheet.dart"

# ── home ────────────────────────────────────────────────────
Move-Dart "Views/Screens/HomeScreen.dart"                        "features/home/screens/home_screen.dart"
Move-Dart "Views/Screens/MainScreen.dart"                        "features/home/screens/main_screen.dart"
Move-Dart "Views/Widgets/Home/AnnouncementsBanner.dart"          "features/home/widgets/announcements_banner.dart"
Move-Dart "Views/Widgets/bottomNavBar.dart"                      "features/home/widgets/bottom_nav_bar.dart"
Move-Dart "Views/Widgets/homeAppBar.dart"                        "features/home/widgets/home_app_bar.dart"
Move-Dart "Views/Widgets/home_drawer.dart"                       "features/home/widgets/home_drawer.dart"
Move-Dart "Views/Widgets/Home/QuickActionsSection.dart"          "features/home/widgets/quick_actions_section.dart"

# ── announcements ───────────────────────────────────────────
Move-Dart "Views/Screens/AnnouncementModalScreen.dart"           "features/announcements/screens/announcement_modal_screen.dart"
Move-Dart "ViewModels/announcement_viewModel.dart"               "features/announcements/view_models/announcement_view_model.dart"
Move-Dart "Models/announcement.dart"                             "features/announcements/models/announcement.dart"

# ── daftar ──────────────────────────────────────────────────
Move-Dart "Views/Screens/Daftar/AttendanceScreen.dart"                          "features/daftar/screens/attendance_screen.dart"
Move-Dart "Views/Screens/Daftar/LeaveManagementScreen.dart"                     "features/daftar/screens/leave_management_screen.dart"
Move-Dart "ViewModels/attendance_viewModel.dart"                                 "features/daftar/view_models/attendance_view_model.dart"
Move-Dart "ViewModels/leave_viewModel.dart"                                      "features/daftar/view_models/leave_view_model.dart"
Move-Dart "API/attendance_apiService.dart"                                       "features/daftar/api/attendance_api_service.dart"
Move-Dart "Models/attendance_shiftLog.dart"                                      "features/daftar/models/attendance_shift_log.dart"
Move-Dart "Providers/location_provider.dart"                                     "features/daftar/providers/location_provider.dart"
Move-Dart "Services/location_sharing_service.dart"                               "features/daftar/services/location_sharing_service.dart"
Move-Dart "Views/Widgets/Attendance/CompactPunchCard.dart"                       "features/daftar/widgets/compact_punch_card.dart"
Move-Dart "Views/Widgets/Attendance/LocationRow.dart"                            "features/daftar/widgets/location_row.dart"
Move-Dart "Views/Widgets/Attendance/PunchButton.dart"                            "features/daftar/widgets/punch_button.dart"
Move-Dart "Views/Widgets/Attendance/PunchCard.dart"                              "features/daftar/widgets/punch_card.dart"
Move-Dart "Views/Widgets/Attendance/PunchStat.dart"                              "features/daftar/widgets/punch_stat.dart"
Move-Dart "Views/Widgets/Attendance/TeamAttendanceSection.dart"                  "features/daftar/widgets/team_attendance_section.dart"
Move-Dart "Views/Widgets/Attendance/TimerDisplay.dart"                           "features/daftar/widgets/timer_display.dart"
Move-Dart "Views/Widgets/Attendance/WorkScheduleSection.dart"                    "features/daftar/widgets/work_schedule_section.dart"
Move-Dart "Views/Widgets/Attendance/Leaves/LeaveCard.dart"                      "features/daftar/widgets/leaves/leave_card.dart"
Move-Dart "Views/Widgets/Attendance/Leaves/LeaveFAB.dart"                       "features/daftar/widgets/leaves/leave_fab.dart"
Move-Dart "Views/Widgets/Attendance/Leaves/LeaveFormComponents.dart"             "features/daftar/widgets/leaves/leave_form_components.dart"
Move-Dart "Views/Widgets/Attendance/Leaves/LeaveOptionsBottomSheet.dart"         "features/daftar/widgets/leaves/leave_options_bottom_sheet.dart"
Move-Dart "Views/Widgets/Attendance/Leaves/OtherLeaveForm.dart"                 "features/daftar/widgets/leaves/other_leave_form.dart"
Move-Dart "Views/Widgets/Attendance/Leaves/ShortLeaveForm.dart"                 "features/daftar/widgets/leaves/short_leave_form.dart"

# ── team_status ─────────────────────────────────────────────
Move-Dart "Views/Screens/TeamStatusScreen.dart"       "features/team_status/screens/team_status_screen.dart"
Move-Dart "ViewModels/teamStatus_viewModel.dart"      "features/team_status/view_models/team_status_view_model.dart"
Move-Dart "Models/userDetailsModel.dart"              "features/team_status/models/user_details_model.dart"

# ── callyn_analytics ────────────────────────────────────────
Move-Dart "Views/Screens/CallynAnalyticsScreen.dart"                   "features/callyn_analytics/screens/callyn_analytics_screen.dart"
Move-Dart "ViewModels/callynAnalytics_viewModel.dart"                  "features/callyn_analytics/view_models/callyn_analytics_view_model.dart"
Move-Dart "API/callyn_apiService.dart"                                  "features/callyn_analytics/api/callyn_api_service.dart"
Move-Dart "Models/callyn_analytics_model.dart"                          "features/callyn_analytics/models/callyn_analytics_model.dart"
Move-Dart "Views/Widgets/CallynAnalytics/AnalyticsSkeleton.dart"       "features/callyn_analytics/widgets/analytics_skeleton.dart"
Move-Dart "Views/Widgets/CallynAnalytics/CallTypeDoughnut.dart"        "features/callyn_analytics/widgets/call_type_doughnut.dart"
Move-Dart "Utils/CallynCardHelper.dart"                                 "features/callyn_analytics/widgets/callyn_card_helper.dart"
Move-Dart "Utils/CallynDateHelper.dart"                                 "features/callyn_analytics/widgets/callyn_date_helper.dart"
Move-Dart "Views/Widgets/CallynAnalytics/EmployeeDropdown.dart"        "features/callyn_analytics/widgets/employee_dropdown.dart"
Move-Dart "Views/Widgets/CallynAnalytics/ExpandableListCard.dart"      "features/callyn_analytics/widgets/expandable_list_card.dart"
Move-Dart "Views/Widgets/CallynAnalytics/FilterTabs.dart"              "features/callyn_analytics/widgets/filter_tabs.dart"
Move-Dart "Views/Widgets/CallynAnalytics/HorizontalBarGraph.dart"      "features/callyn_analytics/widgets/horizontal_bar_graph.dart"
Move-Dart "Views/Widgets/CallynAnalytics/Pills.dart"                   "features/callyn_analytics/widgets/pills.dart"
Move-Dart "Views/Widgets/CallynAnalytics/SingleEmployeeSummary.dart"   "features/callyn_analytics/widgets/single_employee_summary.dart"

# ── modules_analytics ───────────────────────────────────────
Move-Dart "Views/Screens/ModulesAnalyticsScreen.dart"      "features/modules_analytics/screens/modules_analytics_screen.dart"
Move-Dart "ViewModels/modules_analytics_viewModel.dart"    "features/modules_analytics/view_models/modules_analytics_view_model.dart"
Move-Dart "API/analytics_api_service.dart"                 "features/modules_analytics/api/analytics_api_service.dart"
Move-Dart "Models/modules_analytics_model.dart"            "features/modules_analytics/models/modules_analytics_model.dart"
Move-Dart "Providers/module_usage_provider.dart"           "features/modules_analytics/providers/module_usage_provider.dart"
Move-Dart "Services/module_usage_service.dart"             "features/modules_analytics/services/module_usage_service.dart"

# ── marketing ───────────────────────────────────────────────
Move-Dart "Views/Screens/MarketingScreen.dart"             "features/marketing/screens/marketing_screen.dart"
Move-Dart "ViewModels/marketing_viewModel.dart"            "features/marketing/view_models/marketing_view_model.dart"
Move-Dart "API/marketing_api_service.dart"                 "features/marketing/api/marketing_api_service.dart"
Move-Dart "Models/marketing_model.dart"                    "features/marketing/models/marketing_model.dart"
Move-Dart "Utils/marketing_image_util.dart"                "features/marketing/utils/marketing_image_util.dart"
Move-Dart "Views/Widgets/Marketing/AsyncButtons.dart"      "features/marketing/widgets/async_buttons.dart"

# ── operations (parent) + mf_transaction (sub-feature) ─────
Move-Dart "API/operations_apiService.dart"                                              "features/operations/api/operations_api_service.dart"
Move-Dart "Views/Screens/MFTransaction/MFTransScreen.dart"                             "features/operations/mf_transaction/screens/mf_trans_screen.dart"
Move-Dart "Views/Screens/MFTransaction/MFTransFormScreen.dart"                         "features/operations/mf_transaction/screens/mf_trans_form_screen.dart"
Move-Dart "Views/Screens/MFTransaction/MFTransReviewScreen.dart"                       "features/operations/mf_transaction/screens/mf_trans_review_screen.dart"
Move-Dart "Views/Screens/MFTransaction/MFTransCompletedScreen.dart"                    "features/operations/mf_transaction/screens/mf_trans_completed_screen.dart"
Move-Dart "ViewModels/mfTransForm_viewModel.dart"                                       "features/operations/mf_transaction/view_models/mf_trans_form_view_model.dart"
Move-Dart "ViewModels/mfTransaction_viewModel.dart"                                     "features/operations/mf_transaction/view_models/mf_transaction_view_model.dart"
Move-Dart "Models/mftrans_models.dart"                                                  "features/operations/mf_transaction/models/mf_trans_models.dart"
Move-Dart "Views/Widgets/MFTrans/SwitchForm.dart"                                      "features/operations/mf_transaction/widgets/switch_form.dart"
Move-Dart "Views/Widgets/MFTrans/SystematicForm.dart"                                   "features/operations/mf_transaction/widgets/systematic_form.dart"
Move-Dart "Views/Widgets/MFTrans/UccCard.dart"                                          "features/operations/mf_transaction/widgets/ucc_card.dart"
Move-Dart "Views/Widgets/MFTrans/formComponents.dart"                                   "features/operations/mf_transaction/widgets/form_components.dart"
Move-Dart "Views/Widgets/MFTrans/mfTrans_common_widgets.dart"                          "features/operations/mf_transaction/widgets/mf_trans_common_widgets.dart"
Move-Dart "Views/Widgets/MFTrans/purchRedemptionForm.dart"                              "features/operations/mf_transaction/widgets/purch_redemption_form.dart"

# ── investwell_report ───────────────────────────────────────
Move-Dart "Views/Screens/InvestwellReportScreen.dart"          "features/investwell_report/screens/investwell_report_screen.dart"
Move-Dart "ViewModels/investwellReport_viewModel.dart"         "features/investwell_report/view_models/investwell_report_view_model.dart"
Move-Dart "Models/investwell_report_models.dart"               "features/investwell_report/models/investwell_report_models.dart"

# ── route_management ────────────────────────────────────────
Move-Dart "Views/Screens/RouteManagement/RouteManagementDashboardScreen.dart"  "features/route_management/screens/route_management_dashboard_screen.dart"
Move-Dart "Views/Screens/RouteManagement/add_task_screen.dart"                 "features/route_management/screens/add_task_screen.dart"
Move-Dart "Views/Screens/RouteManagement/field_executive_tracking_screen.dart" "features/route_management/screens/field_executive_tracking_screen.dart"
Move-Dart "Views/Screens/RouteManagement/view_route_details_screen.dart"       "features/route_management/screens/view_route_details_screen.dart"
Move-Dart "Views/Screens/RouteManagement/visit_details_screen.dart"            "features/route_management/screens/visit_details_screen.dart"
Move-Dart "ViewModels/routeOptimization_viewModel.dart"                         "features/route_management/view_models/route_optimization_view_model.dart"
Move-Dart "API/route_optimization_api_service.dart"                             "features/route_management/api/route_optimization_api_service.dart"
Move-Dart "Models/route_optimization_models.dart"                               "features/route_management/models/route_optimization_models.dart"
Move-Dart "Utils/route_visit_image_util.dart"                                   "features/route_management/utils/route_visit_image_util.dart"
Move-Dart "Views/Widgets/RouteManagement/edit_task_bottom_sheet.dart"          "features/route_management/widgets/edit_task_bottom_sheet.dart"
Move-Dart "Views/Widgets/RouteManagement/modern_visit_card.dart"               "features/route_management/widgets/modern_visit_card.dart"
Move-Dart "Views/Widgets/ModuleAppBar.dart"                                     "features/route_management/widgets/module_app_bar.dart"
Move-Dart "Views/Widgets/RouteManagement/visit_cards.dart"                     "features/route_management/widgets/visit_cards.dart"
Move-Dart "Views/Widgets/RouteManagement/visit_details_components.dart"        "features/route_management/widgets/visit_details_components.dart"
Move-Dart "Views/Widgets/RouteManagement/visit_image_gallery_viewer.dart"      "features/route_management/widgets/visit_image_gallery_viewer.dart"

# ── app_store ───────────────────────────────────────────────
Move-Dart "Views/Screens/StoreScreen.dart"               "features/app_store/screens/store_screen.dart"
Move-Dart "ViewModels/appCard_viewModel.dart"             "features/app_store/view_models/app_card_view_model.dart"
Move-Dart "Models/appModel.dart"                          "features/app_store/models/app_model.dart"
Move-Dart "Providers/app_provider.dart"                   "features/app_store/providers/app_provider.dart"
Move-Dart "Providers/download_state_provider.dart"        "features/app_store/providers/download_state_provider.dart"
Move-Dart "Views/Widgets/AppStore/appCard.dart"           "features/app_store/widgets/app_card.dart"
Move-Dart "Views/Widgets/AppStore/download_button.dart"   "features/app_store/widgets/download_button.dart"

# ── modules ─────────────────────────────────────────────────
Move-Dart "Views/Screens/ModuleScreen.dart"              "features/modules/screens/module_screen.dart"
Move-Dart "Models/moduleScreen_data.dart"                "features/modules/models/module_screen_data.dart"
Move-Dart "Utils/ModuleTransitionAnimation.dart"         "features/modules/utils/module_transition_animation.dart"
Move-Dart "Views/Widgets/api_error_state_view.dart"      "features/modules/widgets/api_error_state_view.dart"

Write-Host "`n=== File moves complete ===" -ForegroundColor Cyan

# ============================================================
# PHASE 3 — Rewrite imports to package: style
# This converts ALL internal imports to absolute package imports,
# making them location-independent.
# ============================================================
Write-Host "`n=== PHASE 3: Rewriting imports ===" -ForegroundColor Cyan

$pkg = "mnivesh_central"

# Map: old relative/partial path fragment → new package path (no quotes, no import keyword)
# Each entry: @{ Old = "fragment to find inside import strings"; New = "package:pkg/new/path/file.dart" }
$importMap = @(
    # ── core/api ──────────────────────────────────────────
    @{ Old = "API/api_client.dart";          New = "package:$pkg/core/api/api_client.dart" },
    @{ Old = "API/api_config.dart";          New = "package:$pkg/core/api/api_config.dart" },
    @{ Old = "API/api_service.dart";         New = "package:$pkg/core/api/api_service.dart" },

    # ── core/services ─────────────────────────────────────
    @{ Old = "Services/analytics_service.dart";                     New = "package:$pkg/core/services/analytics_service.dart" },
    @{ Old = "Services/app_tokens_service.dart";                    New = "package:$pkg/core/services/app_tokens_service.dart" },
    @{ Old = "Services/bootstrap_service.dart";                     New = "package:$pkg/core/services/bootstrap_service.dart" },
    @{ Old = "Services/cache_service.dart";                         New = "package:$pkg/core/services/cache_service.dart" },
    @{ Old = "Services/connectivity_service.dart";                  New = "package:$pkg/core/services/connectivity_service.dart" },
    @{ Old = "Services/CustomHapticService.dart";                   New = "package:$pkg/core/services/custom_haptic_service.dart" },
    @{ Old = "Services/download_service.dart";                      New = "package:$pkg/core/services/download_service.dart" },
    @{ Old = "Services/fcm_service.dart";                           New = "package:$pkg/core/services/fcm_service.dart" },
    @{ Old = "Services/FirebasePerformanceNetworkInterceptor.dart"; New = "package:$pkg/core/services/firebase_performance_network_interceptor.dart" },
    @{ Old = "Services/permission_helper.dart";                     New = "package:$pkg/core/services/permission_helper.dart" },
    @{ Old = "Services/snackBar_Service.dart";                      New = "package:$pkg/core/services/snack_bar_service.dart" },
    @{ Old = "Services/sync_service.dart";                          New = "package:$pkg/core/services/sync_service.dart" },
    @{ Old = "Services/updater_service.dart";                       New = "package:$pkg/core/services/updater_service.dart" },

    # ── core/providers ────────────────────────────────────
    @{ Old = "Providers/profile_image_provider.dart"; New = "package:$pkg/core/providers/profile_image_provider.dart" },

    # ── core/theme ────────────────────────────────────────
    @{ Old = "Themes/AppTextStyle.dart"; New = "package:$pkg/core/theme/app_text_style.dart" },
    @{ Old = "Themes/AppTheme.dart";     New = "package:$pkg/core/theme/app_theme.dart" },

    # ── core/utils ────────────────────────────────────────
    @{ Old = "Utils/Dimensions.dart";           New = "package:$pkg/core/utils/dimensions.dart" },
    @{ Old = "Utils/DiscardChangesDialog.dart"; New = "package:$pkg/core/utils/discard_changes_dialog.dart" },
    @{ Old = "Utils/DismissKeyboard.dart";      New = "package:$pkg/core/utils/dismiss_keyboard.dart" },

    # ── features/auth ─────────────────────────────────────
    @{ Old = "Views/Screens/LoginScreen.dart";                    New = "package:$pkg/features/auth/screens/login_screen.dart" },
    @{ Old = "ViewModels/login_viewModel.dart";                   New = "package:$pkg/features/auth/view_models/login_view_model.dart" },
    @{ Old = "Managers/AuthManager.dart";                         New = "package:$pkg/features/auth/managers/auth_manager.dart" },
    @{ Old = "Managers/AuthWrapper.dart";                         New = "package:$pkg/features/auth/managers/auth_wrapper.dart" },
    @{ Old = "Managers/ChildSsoRequestHandler.dart";              New = "package:$pkg/features/auth/managers/child_sso_request_handler.dart" },
    @{ Old = "Views/Widgets/sso_authorization_bottom_sheet.dart"; New = "package:$pkg/features/auth/widgets/sso_authorization_bottom_sheet.dart" },

    # ── features/home ─────────────────────────────────────
    @{ Old = "Views/Screens/HomeScreen.dart";                  New = "package:$pkg/features/home/screens/home_screen.dart" },
    @{ Old = "Views/Screens/MainScreen.dart";                  New = "package:$pkg/features/home/screens/main_screen.dart" },
    @{ Old = "Views/Widgets/Home/AnnouncementsBanner.dart";    New = "package:$pkg/features/home/widgets/announcements_banner.dart" },
    @{ Old = "Views/Widgets/bottomNavBar.dart";                New = "package:$pkg/features/home/widgets/bottom_nav_bar.dart" },
    @{ Old = "Views/Widgets/homeAppBar.dart";                  New = "package:$pkg/features/home/widgets/home_app_bar.dart" },
    @{ Old = "Views/Widgets/home_drawer.dart";                 New = "package:$pkg/features/home/widgets/home_drawer.dart" },
    @{ Old = "Views/Widgets/Home/QuickActionsSection.dart";    New = "package:$pkg/features/home/widgets/quick_actions_section.dart" },

    # ── features/announcements ────────────────────────────
    @{ Old = "Views/Screens/AnnouncementModalScreen.dart";   New = "package:$pkg/features/announcements/screens/announcement_modal_screen.dart" },
    @{ Old = "ViewModels/announcement_viewModel.dart";        New = "package:$pkg/features/announcements/view_models/announcement_view_model.dart" },
    @{ Old = "Models/announcement.dart";                      New = "package:$pkg/features/announcements/models/announcement.dart" },

    # ── features/daftar ───────────────────────────────────
    @{ Old = "Views/Screens/Daftar/AttendanceScreen.dart";                          New = "package:$pkg/features/daftar/screens/attendance_screen.dart" },
    @{ Old = "Views/Screens/Daftar/LeaveManagementScreen.dart";                     New = "package:$pkg/features/daftar/screens/leave_management_screen.dart" },
    @{ Old = "ViewModels/attendance_viewModel.dart";                                 New = "package:$pkg/features/daftar/view_models/attendance_view_model.dart" },
    @{ Old = "ViewModels/leave_viewModel.dart";                                      New = "package:$pkg/features/daftar/view_models/leave_view_model.dart" },
    @{ Old = "API/attendance_apiService.dart";                                       New = "package:$pkg/features/daftar/api/attendance_api_service.dart" },
    @{ Old = "Models/attendance_shiftLog.dart";                                      New = "package:$pkg/features/daftar/models/attendance_shift_log.dart" },
    @{ Old = "Providers/location_provider.dart";                                     New = "package:$pkg/features/daftar/providers/location_provider.dart" },
    @{ Old = "Services/location_sharing_service.dart";                               New = "package:$pkg/features/daftar/services/location_sharing_service.dart" },
    @{ Old = "Views/Widgets/Attendance/CompactPunchCard.dart";                       New = "package:$pkg/features/daftar/widgets/compact_punch_card.dart" },
    @{ Old = "Views/Widgets/Attendance/LocationRow.dart";                            New = "package:$pkg/features/daftar/widgets/location_row.dart" },
    @{ Old = "Views/Widgets/Attendance/PunchButton.dart";                            New = "package:$pkg/features/daftar/widgets/punch_button.dart" },
    @{ Old = "Views/Widgets/Attendance/PunchCard.dart";                              New = "package:$pkg/features/daftar/widgets/punch_card.dart" },
    @{ Old = "Views/Widgets/Attendance/PunchStat.dart";                              New = "package:$pkg/features/daftar/widgets/punch_stat.dart" },
    @{ Old = "Views/Widgets/Attendance/TeamAttendanceSection.dart";                  New = "package:$pkg/features/daftar/widgets/team_attendance_section.dart" },
    @{ Old = "Views/Widgets/Attendance/TimerDisplay.dart";                           New = "package:$pkg/features/daftar/widgets/timer_display.dart" },
    @{ Old = "Views/Widgets/Attendance/WorkScheduleSection.dart";                    New = "package:$pkg/features/daftar/widgets/work_schedule_section.dart" },
    @{ Old = "Views/Widgets/Attendance/Leaves/LeaveCard.dart";                      New = "package:$pkg/features/daftar/widgets/leaves/leave_card.dart" },
    @{ Old = "Views/Widgets/Attendance/Leaves/LeaveFAB.dart";                       New = "package:$pkg/features/daftar/widgets/leaves/leave_fab.dart" },
    @{ Old = "Views/Widgets/Attendance/Leaves/LeaveFormComponents.dart";             New = "package:$pkg/features/daftar/widgets/leaves/leave_form_components.dart" },
    @{ Old = "Views/Widgets/Attendance/Leaves/LeaveOptionsBottomSheet.dart";         New = "package:$pkg/features/daftar/widgets/leaves/leave_options_bottom_sheet.dart" },
    @{ Old = "Views/Widgets/Attendance/Leaves/OtherLeaveForm.dart";                 New = "package:$pkg/features/daftar/widgets/leaves/other_leave_form.dart" },
    @{ Old = "Views/Widgets/Attendance/Leaves/ShortLeaveForm.dart";                 New = "package:$pkg/features/daftar/widgets/leaves/short_leave_form.dart" },

    # ── features/team_status ──────────────────────────────
    @{ Old = "Views/Screens/TeamStatusScreen.dart";      New = "package:$pkg/features/team_status/screens/team_status_screen.dart" },
    @{ Old = "ViewModels/teamStatus_viewModel.dart";     New = "package:$pkg/features/team_status/view_models/team_status_view_model.dart" },
    @{ Old = "Models/userDetailsModel.dart";             New = "package:$pkg/features/team_status/models/user_details_model.dart" },

    # ── features/callyn_analytics ─────────────────────────
    @{ Old = "Views/Screens/CallynAnalyticsScreen.dart";                   New = "package:$pkg/features/callyn_analytics/screens/callyn_analytics_screen.dart" },
    @{ Old = "ViewModels/callynAnalytics_viewModel.dart";                  New = "package:$pkg/features/callyn_analytics/view_models/callyn_analytics_view_model.dart" },
    @{ Old = "API/callyn_apiService.dart";                                  New = "package:$pkg/features/callyn_analytics/api/callyn_api_service.dart" },
    @{ Old = "Models/callyn_analytics_model.dart";                          New = "package:$pkg/features/callyn_analytics/models/callyn_analytics_model.dart" },
    @{ Old = "Views/Widgets/CallynAnalytics/AnalyticsSkeleton.dart";       New = "package:$pkg/features/callyn_analytics/widgets/analytics_skeleton.dart" },
    @{ Old = "Views/Widgets/CallynAnalytics/CallTypeDoughnut.dart";        New = "package:$pkg/features/callyn_analytics/widgets/call_type_doughnut.dart" },
    @{ Old = "Utils/CallynCardHelper.dart";                                 New = "package:$pkg/features/callyn_analytics/widgets/callyn_card_helper.dart" },
    @{ Old = "Utils/CallynDateHelper.dart";                                 New = "package:$pkg/features/callyn_analytics/widgets/callyn_date_helper.dart" },
    @{ Old = "Views/Widgets/CallynAnalytics/EmployeeDropdown.dart";        New = "package:$pkg/features/callyn_analytics/widgets/employee_dropdown.dart" },
    @{ Old = "Views/Widgets/CallynAnalytics/ExpandableListCard.dart";      New = "package:$pkg/features/callyn_analytics/widgets/expandable_list_card.dart" },
    @{ Old = "Views/Widgets/CallynAnalytics/FilterTabs.dart";              New = "package:$pkg/features/callyn_analytics/widgets/filter_tabs.dart" },
    @{ Old = "Views/Widgets/CallynAnalytics/HorizontalBarGraph.dart";      New = "package:$pkg/features/callyn_analytics/widgets/horizontal_bar_graph.dart" },
    @{ Old = "Views/Widgets/CallynAnalytics/Pills.dart";                   New = "package:$pkg/features/callyn_analytics/widgets/pills.dart" },
    @{ Old = "Views/Widgets/CallynAnalytics/SingleEmployeeSummary.dart";   New = "package:$pkg/features/callyn_analytics/widgets/single_employee_summary.dart" },

    # ── features/modules_analytics ────────────────────────
    @{ Old = "Views/Screens/ModulesAnalyticsScreen.dart";      New = "package:$pkg/features/modules_analytics/screens/modules_analytics_screen.dart" },
    @{ Old = "ViewModels/modules_analytics_viewModel.dart";    New = "package:$pkg/features/modules_analytics/view_models/modules_analytics_view_model.dart" },
    @{ Old = "API/analytics_api_service.dart";                 New = "package:$pkg/features/modules_analytics/api/analytics_api_service.dart" },
    @{ Old = "Models/modules_analytics_model.dart";            New = "package:$pkg/features/modules_analytics/models/modules_analytics_model.dart" },
    @{ Old = "Providers/module_usage_provider.dart";           New = "package:$pkg/features/modules_analytics/providers/module_usage_provider.dart" },
    @{ Old = "Services/module_usage_service.dart";             New = "package:$pkg/features/modules_analytics/services/module_usage_service.dart" },

    # ── features/marketing ────────────────────────────────
    @{ Old = "Views/Screens/MarketingScreen.dart";             New = "package:$pkg/features/marketing/screens/marketing_screen.dart" },
    @{ Old = "ViewModels/marketing_viewModel.dart";            New = "package:$pkg/features/marketing/view_models/marketing_view_model.dart" },
    @{ Old = "API/marketing_api_service.dart";                 New = "package:$pkg/features/marketing/api/marketing_api_service.dart" },
    @{ Old = "Models/marketing_model.dart";                    New = "package:$pkg/features/marketing/models/marketing_model.dart" },
    @{ Old = "Utils/marketing_image_util.dart";                New = "package:$pkg/features/marketing/utils/marketing_image_util.dart" },
    @{ Old = "Views/Widgets/Marketing/AsyncButtons.dart";      New = "package:$pkg/features/marketing/widgets/async_buttons.dart" },

    # ── features/operations + mf_transaction ──────────────
    @{ Old = "API/operations_apiService.dart";                                              New = "package:$pkg/features/operations/api/operations_api_service.dart" },
    @{ Old = "Views/Screens/MFTransaction/MFTransScreen.dart";                             New = "package:$pkg/features/operations/mf_transaction/screens/mf_trans_screen.dart" },
    @{ Old = "Views/Screens/MFTransaction/MFTransFormScreen.dart";                         New = "package:$pkg/features/operations/mf_transaction/screens/mf_trans_form_screen.dart" },
    @{ Old = "Views/Screens/MFTransaction/MFTransReviewScreen.dart";                       New = "package:$pkg/features/operations/mf_transaction/screens/mf_trans_review_screen.dart" },
    @{ Old = "Views/Screens/MFTransaction/MFTransCompletedScreen.dart";                    New = "package:$pkg/features/operations/mf_transaction/screens/mf_trans_completed_screen.dart" },
    @{ Old = "ViewModels/mfTransForm_viewModel.dart";                                       New = "package:$pkg/features/operations/mf_transaction/view_models/mf_trans_form_view_model.dart" },
    @{ Old = "ViewModels/mfTransaction_viewModel.dart";                                     New = "package:$pkg/features/operations/mf_transaction/view_models/mf_transaction_view_model.dart" },
    @{ Old = "Models/mftrans_models.dart";                                                  New = "package:$pkg/features/operations/mf_transaction/models/mf_trans_models.dart" },
    @{ Old = "Views/Widgets/MFTrans/SwitchForm.dart";                                      New = "package:$pkg/features/operations/mf_transaction/widgets/switch_form.dart" },
    @{ Old = "Views/Widgets/MFTrans/SystematicForm.dart";                                   New = "package:$pkg/features/operations/mf_transaction/widgets/systematic_form.dart" },
    @{ Old = "Views/Widgets/MFTrans/UccCard.dart";                                          New = "package:$pkg/features/operations/mf_transaction/widgets/ucc_card.dart" },
    @{ Old = "Views/Widgets/MFTrans/formComponents.dart";                                   New = "package:$pkg/features/operations/mf_transaction/widgets/form_components.dart" },
    @{ Old = "Views/Widgets/MFTrans/mfTrans_common_widgets.dart";                          New = "package:$pkg/features/operations/mf_transaction/widgets/mf_trans_common_widgets.dart" },
    @{ Old = "Views/Widgets/MFTrans/purchRedemptionForm.dart";                              New = "package:$pkg/features/operations/mf_transaction/widgets/purch_redemption_form.dart" },

    # ── features/investwell_report ────────────────────────
    @{ Old = "Views/Screens/InvestwellReportScreen.dart";          New = "package:$pkg/features/investwell_report/screens/investwell_report_screen.dart" },
    @{ Old = "ViewModels/investwellReport_viewModel.dart";         New = "package:$pkg/features/investwell_report/view_models/investwell_report_view_model.dart" },
    @{ Old = "Models/investwell_report_models.dart";               New = "package:$pkg/features/investwell_report/models/investwell_report_models.dart" },

    # ── features/route_management ─────────────────────────
    @{ Old = "Views/Screens/RouteManagement/RouteManagementDashboardScreen.dart";  New = "package:$pkg/features/route_management/screens/route_management_dashboard_screen.dart" },
    @{ Old = "Views/Screens/RouteManagement/add_task_screen.dart";                 New = "package:$pkg/features/route_management/screens/add_task_screen.dart" },
    @{ Old = "Views/Screens/RouteManagement/field_executive_tracking_screen.dart"; New = "package:$pkg/features/route_management/screens/field_executive_tracking_screen.dart" },
    @{ Old = "Views/Screens/RouteManagement/view_route_details_screen.dart";       New = "package:$pkg/features/route_management/screens/view_route_details_screen.dart" },
    @{ Old = "Views/Screens/RouteManagement/visit_details_screen.dart";            New = "package:$pkg/features/route_management/screens/visit_details_screen.dart" },
    @{ Old = "ViewModels/routeOptimization_viewModel.dart";                         New = "package:$pkg/features/route_management/view_models/route_optimization_view_model.dart" },
    @{ Old = "API/route_optimization_api_service.dart";                             New = "package:$pkg/features/route_management/api/route_optimization_api_service.dart" },
    @{ Old = "Models/route_optimization_models.dart";                               New = "package:$pkg/features/route_management/models/route_optimization_models.dart" },
    @{ Old = "Utils/route_visit_image_util.dart";                                   New = "package:$pkg/features/route_management/utils/route_visit_image_util.dart" },
    @{ Old = "Views/Widgets/RouteManagement/edit_task_bottom_sheet.dart";          New = "package:$pkg/features/route_management/widgets/edit_task_bottom_sheet.dart" },
    @{ Old = "Views/Widgets/RouteManagement/modern_visit_card.dart";               New = "package:$pkg/features/route_management/widgets/modern_visit_card.dart" },
    @{ Old = "Views/Widgets/ModuleAppBar.dart";                                     New = "package:$pkg/features/route_management/widgets/module_app_bar.dart" },
    @{ Old = "Views/Widgets/RouteManagement/visit_cards.dart";                     New = "package:$pkg/features/route_management/widgets/visit_cards.dart" },
    @{ Old = "Views/Widgets/RouteManagement/visit_details_components.dart";        New = "package:$pkg/features/route_management/widgets/visit_details_components.dart" },
    @{ Old = "Views/Widgets/RouteManagement/visit_image_gallery_viewer.dart";      New = "package:$pkg/features/route_management/widgets/visit_image_gallery_viewer.dart" },

    # ── features/app_store ────────────────────────────────
    @{ Old = "Views/Screens/StoreScreen.dart";               New = "package:$pkg/features/app_store/screens/store_screen.dart" },
    @{ Old = "ViewModels/appCard_viewModel.dart";             New = "package:$pkg/features/app_store/view_models/app_card_view_model.dart" },
    @{ Old = "Models/appModel.dart";                          New = "package:$pkg/features/app_store/models/app_model.dart" },
    @{ Old = "Providers/app_provider.dart";                   New = "package:$pkg/features/app_store/providers/app_provider.dart" },
    @{ Old = "Providers/download_state_provider.dart";        New = "package:$pkg/features/app_store/providers/download_state_provider.dart" },
    @{ Old = "Views/Widgets/AppStore/appCard.dart";           New = "package:$pkg/features/app_store/widgets/app_card.dart" },
    @{ Old = "Views/Widgets/AppStore/download_button.dart";   New = "package:$pkg/features/app_store/widgets/download_button.dart" },

    # ── features/modules ──────────────────────────────────
    @{ Old = "Views/Screens/ModuleScreen.dart";              New = "package:$pkg/features/modules/screens/module_screen.dart" },
    @{ Old = "Models/moduleScreen_data.dart";                New = "package:$pkg/features/modules/models/module_screen_data.dart" },
    @{ Old = "Utils/ModuleTransitionAnimation.dart";         New = "package:$pkg/features/modules/utils/module_transition_animation.dart" },
    @{ Old = "Views/Widgets/api_error_state_view.dart";      New = "package:$pkg/features/modules/widgets/api_error_state_view.dart" }
)

# Get all dart files in lib/
$dartFiles = Get-ChildItem -Path $lib -Recurse -Filter "*.dart" | Where-Object { -not $_.FullName.Contains("\.dart_tool\") }
Write-Host "  Found $($dartFiles.Count) dart files to process" -ForegroundColor Gray

$totalReplaced = 0

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $original = $content
    $changed = $false

    foreach ($entry in $importMap) {
        # Match import lines containing the old path (relative or package-style)
        # We match the fragment anywhere in an import string
        $oldFrag = [regex]::Escape($entry.Old)
        # Replace any import "...OldFrag..." or import '...OldFrag...'
        $pattern = "(?<=import\s+['""])([^'""]*)" + $oldFrag + "([^'""]*)"
        if ($content -match $oldFrag) {
            # Direct replacement: find the exact quoted import string containing the fragment
            $content = $content -replace ("import '([^']*)" + $oldFrag + "([^']*)'"), ("import '" + $entry.New + "'")
            $content = $content -replace ('import "([^"]*)"' -replace '([^"]*)' + $oldFrag + '([^"]*)', ('import "' + $entry.New + '"')), ("import `"" + $entry.New + "`"")
            $changed = $true
        }
    }

    # Also fix intra-feature relative imports that still point to old paths
    # These are imports using ../ that reference old folder names
    # Replace any remaining relative imports from old dirs
    $oldDirs = @("API", "Managers", "Models", "Providers", "Services", "Themes", "Utils", "ViewModels", "Views")
    foreach ($dir in $oldDirs) {
        if ($content -match "'[./]*$dir/") {
            Write-Host "  [WARN] $($file.Name) still has relative import from $dir/" -ForegroundColor Yellow
        }
    }

    if ($changed) {
        Set-Content -Path $file.FullName -Value $content -Encoding UTF8 -NoNewline
        $totalReplaced++
    }
}

Write-Host "  Updated imports in $totalReplaced files" -ForegroundColor Green

# ============================================================
# PHASE 4 — Remove empty old directories
# ============================================================
Write-Host "`n=== PHASE 4: Removing old directories ===" -ForegroundColor Cyan

$oldDirsToRemove = @("API", "Managers", "Models", "Providers", "Services", "Themes", "Utils", "ViewModels", "Views")
foreach ($dir in $oldDirsToRemove) {
    $path = Join-Path $lib $dir
    if (Test-Path $path) {
        $remaining = Get-ChildItem $path -Recurse -File
        if ($remaining.Count -eq 0) {
            Remove-Item $path -Recurse -Force
            Write-Host "  [DELETED] $dir/" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] $dir/ still has $($remaining.Count) file(s) — not deleted:" -ForegroundColor Yellow
            $remaining | ForEach-Object { Write-Host "    $_" -ForegroundColor Yellow }
        }
    }
}

Write-Host "`n=== Refactor complete! Run: flutter analyze ===" -ForegroundColor Cyan
