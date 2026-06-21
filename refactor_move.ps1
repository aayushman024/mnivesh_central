# ============================================================
# mnivesh_central — Phase 1+2: Move Files
# ============================================================

$lib = "lib"

function Move-Dart {
    param([string]$src, [string]$dst)
    $srcPath = Join-Path $lib $src
    $dstPath = Join-Path $lib $dst
    if (-not (Test-Path $srcPath)) {
        Write-Host "  [SKIP] not found: $src" -ForegroundColor Yellow
        return
    }
    $dstDir = Split-Path $dstPath -Parent
    if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Path $dstDir -Force | Out-Null }
    Move-Item -Path $srcPath -Destination $dstPath -Force
    Write-Host "  [OK] $src" -ForegroundColor Green
}

Write-Host "=== PHASE 1: core/ ===" -ForegroundColor Cyan

Move-Dart "API/api_client.dart"          "core/api/api_client.dart"
Move-Dart "API/api_config.dart"          "core/api/api_config.dart"
Move-Dart "API/api_service.dart"         "core/api/api_service.dart"

Move-Dart "Services/analytics_service.dart"                     "core/services/analytics_service.dart"
Move-Dart "Services/app_tokens_service.dart"                    "core/services/app_tokens_service.dart"
Move-Dart "Services/bootstrap_service.dart"                     "core/services/bootstrap_service.dart"
Move-Dart "Services/cache_service.dart"                         "core/services/cache_service.dart"
Move-Dart "Services/connectivity_service.dart"                  "core/services/connectivity_service.dart"
Move-Dart "Services/CustomHapticService.dart"                   "core/services/custom_haptic_service.dart"
Move-Dart "Services/download_service.dart"                      "core/services/download_service.dart"
Move-Dart "Services/fcm_service.dart"                           "core/services/fcm_service.dart"
Move-Dart "Services/FirebasePerformanceNetworkInterceptor.dart" "core/services/firebase_performance_network_interceptor.dart"
Move-Dart "Services/permission_helper.dart"                     "core/services/permission_helper.dart"
Move-Dart "Services/snackBar_Service.dart"                      "core/services/snack_bar_service.dart"
Move-Dart "Services/sync_service.dart"                          "core/services/sync_service.dart"
Move-Dart "Services/updater_service.dart"                       "core/services/updater_service.dart"

Move-Dart "Providers/profile_image_provider.dart"  "core/providers/profile_image_provider.dart"

Move-Dart "Themes/AppTextStyle.dart"  "core/theme/app_text_style.dart"
Move-Dart "Themes/AppTheme.dart"      "core/theme/app_theme.dart"

Move-Dart "Utils/Dimensions.dart"           "core/utils/dimensions.dart"
Move-Dart "Utils/DiscardChangesDialog.dart" "core/utils/discard_changes_dialog.dart"
Move-Dart "Utils/DismissKeyboard.dart"      "core/utils/dismiss_keyboard.dart"

Write-Host "`n=== PHASE 2: features/ ===" -ForegroundColor Cyan

# auth
Move-Dart "Views/Screens/LoginScreen.dart"                     "features/auth/screens/login_screen.dart"
Move-Dart "ViewModels/login_viewModel.dart"                    "features/auth/view_models/login_view_model.dart"
Move-Dart "Managers/AuthManager.dart"                          "features/auth/managers/auth_manager.dart"
Move-Dart "Managers/AuthWrapper.dart"                          "features/auth/managers/auth_wrapper.dart"
Move-Dart "Managers/ChildSsoRequestHandler.dart"               "features/auth/managers/child_sso_request_handler.dart"
Move-Dart "Views/Widgets/sso_authorization_bottom_sheet.dart"  "features/auth/widgets/sso_authorization_bottom_sheet.dart"

# home
Move-Dart "Views/Screens/HomeScreen.dart"                     "features/home/screens/home_screen.dart"
Move-Dart "Views/Screens/MainScreen.dart"                     "features/home/screens/main_screen.dart"
Move-Dart "Views/Widgets/Home/AnnouncementsBanner.dart"       "features/home/widgets/announcements_banner.dart"
Move-Dart "Views/Widgets/bottomNavBar.dart"                   "features/home/widgets/bottom_nav_bar.dart"
Move-Dart "Views/Widgets/homeAppBar.dart"                     "features/home/widgets/home_app_bar.dart"
Move-Dart "Views/Widgets/home_drawer.dart"                    "features/home/widgets/home_drawer.dart"
Move-Dart "Views/Widgets/Home/QuickActionsSection.dart"       "features/home/widgets/quick_actions_section.dart"

# announcements
Move-Dart "Views/Screens/AnnouncementModalScreen.dart"         "features/announcements/screens/announcement_modal_screen.dart"
Move-Dart "ViewModels/announcement_viewModel.dart"             "features/announcements/view_models/announcement_view_model.dart"
Move-Dart "Models/announcement.dart"                           "features/announcements/models/announcement.dart"

# daftar
Move-Dart "Views/Screens/Daftar/AttendanceScreen.dart"                   "features/daftar/screens/attendance_screen.dart"
Move-Dart "Views/Screens/Daftar/LeaveManagementScreen.dart"              "features/daftar/screens/leave_management_screen.dart"
Move-Dart "ViewModels/attendance_viewModel.dart"                          "features/daftar/view_models/attendance_view_model.dart"
Move-Dart "ViewModels/leave_viewModel.dart"                               "features/daftar/view_models/leave_view_model.dart"
Move-Dart "API/attendance_apiService.dart"                                "features/daftar/api/attendance_api_service.dart"
Move-Dart "Models/attendance_shiftLog.dart"                               "features/daftar/models/attendance_shift_log.dart"
Move-Dart "Providers/location_provider.dart"                              "features/daftar/providers/location_provider.dart"
Move-Dart "Services/location_sharing_service.dart"                        "features/daftar/services/location_sharing_service.dart"
Move-Dart "Views/Widgets/Attendance/CompactPunchCard.dart"                "features/daftar/widgets/compact_punch_card.dart"
Move-Dart "Views/Widgets/Attendance/LocationRow.dart"                     "features/daftar/widgets/location_row.dart"
Move-Dart "Views/Widgets/Attendance/PunchButton.dart"                     "features/daftar/widgets/punch_button.dart"
Move-Dart "Views/Widgets/Attendance/PunchCard.dart"                       "features/daftar/widgets/punch_card.dart"
Move-Dart "Views/Widgets/Attendance/PunchStat.dart"                       "features/daftar/widgets/punch_stat.dart"
Move-Dart "Views/Widgets/Attendance/TeamAttendanceSection.dart"           "features/daftar/widgets/team_attendance_section.dart"
Move-Dart "Views/Widgets/Attendance/TimerDisplay.dart"                    "features/daftar/widgets/timer_display.dart"
Move-Dart "Views/Widgets/Attendance/WorkScheduleSection.dart"             "features/daftar/widgets/work_schedule_section.dart"
Move-Dart "Views/Widgets/Attendance/Leaves/LeaveCard.dart"               "features/daftar/widgets/leaves/leave_card.dart"
Move-Dart "Views/Widgets/Attendance/Leaves/LeaveFAB.dart"                "features/daftar/widgets/leaves/leave_fab.dart"
Move-Dart "Views/Widgets/Attendance/Leaves/LeaveFormComponents.dart"      "features/daftar/widgets/leaves/leave_form_components.dart"
Move-Dart "Views/Widgets/Attendance/Leaves/LeaveOptionsBottomSheet.dart"  "features/daftar/widgets/leaves/leave_options_bottom_sheet.dart"
Move-Dart "Views/Widgets/Attendance/Leaves/OtherLeaveForm.dart"          "features/daftar/widgets/leaves/other_leave_form.dart"
Move-Dart "Views/Widgets/Attendance/Leaves/ShortLeaveForm.dart"          "features/daftar/widgets/leaves/short_leave_form.dart"

# team_status
Move-Dart "Views/Screens/TeamStatusScreen.dart"    "features/team_status/screens/team_status_screen.dart"
Move-Dart "ViewModels/teamStatus_viewModel.dart"   "features/team_status/view_models/team_status_view_model.dart"
Move-Dart "Models/userDetailsModel.dart"           "features/team_status/models/user_details_model.dart"

# callyn_analytics
Move-Dart "Views/Screens/CallynAnalyticsScreen.dart"                  "features/callyn_analytics/screens/callyn_analytics_screen.dart"
Move-Dart "ViewModels/callynAnalytics_viewModel.dart"                 "features/callyn_analytics/view_models/callyn_analytics_view_model.dart"
Move-Dart "API/callyn_apiService.dart"                                 "features/callyn_analytics/api/callyn_api_service.dart"
Move-Dart "Models/callyn_analytics_model.dart"                         "features/callyn_analytics/models/callyn_analytics_model.dart"
Move-Dart "Views/Widgets/CallynAnalytics/AnalyticsSkeleton.dart"      "features/callyn_analytics/widgets/analytics_skeleton.dart"
Move-Dart "Views/Widgets/CallynAnalytics/CallTypeDoughnut.dart"       "features/callyn_analytics/widgets/call_type_doughnut.dart"
Move-Dart "Utils/CallynCardHelper.dart"                                "features/callyn_analytics/widgets/callyn_card_helper.dart"
Move-Dart "Utils/CallynDateHelper.dart"                                "features/callyn_analytics/widgets/callyn_date_helper.dart"
Move-Dart "Views/Widgets/CallynAnalytics/EmployeeDropdown.dart"       "features/callyn_analytics/widgets/employee_dropdown.dart"
Move-Dart "Views/Widgets/CallynAnalytics/ExpandableListCard.dart"     "features/callyn_analytics/widgets/expandable_list_card.dart"
Move-Dart "Views/Widgets/CallynAnalytics/FilterTabs.dart"             "features/callyn_analytics/widgets/filter_tabs.dart"
Move-Dart "Views/Widgets/CallynAnalytics/HorizontalBarGraph.dart"     "features/callyn_analytics/widgets/horizontal_bar_graph.dart"
Move-Dart "Views/Widgets/CallynAnalytics/Pills.dart"                  "features/callyn_analytics/widgets/pills.dart"
Move-Dart "Views/Widgets/CallynAnalytics/SingleEmployeeSummary.dart"  "features/callyn_analytics/widgets/single_employee_summary.dart"

# modules_analytics
Move-Dart "Views/Screens/ModulesAnalyticsScreen.dart"   "features/modules_analytics/screens/modules_analytics_screen.dart"
Move-Dart "ViewModels/modules_analytics_viewModel.dart"  "features/modules_analytics/view_models/modules_analytics_view_model.dart"
Move-Dart "API/analytics_api_service.dart"               "features/modules_analytics/api/analytics_api_service.dart"
Move-Dart "Models/modules_analytics_model.dart"          "features/modules_analytics/models/modules_analytics_model.dart"
Move-Dart "Providers/module_usage_provider.dart"         "features/modules_analytics/providers/module_usage_provider.dart"
Move-Dart "Services/module_usage_service.dart"           "features/modules_analytics/services/module_usage_service.dart"

# marketing
Move-Dart "Views/Screens/MarketingScreen.dart"           "features/marketing/screens/marketing_screen.dart"
Move-Dart "ViewModels/marketing_viewModel.dart"          "features/marketing/view_models/marketing_view_model.dart"
Move-Dart "API/marketing_api_service.dart"               "features/marketing/api/marketing_api_service.dart"
Move-Dart "Models/marketing_model.dart"                  "features/marketing/models/marketing_model.dart"
Move-Dart "Utils/marketing_image_util.dart"              "features/marketing/utils/marketing_image_util.dart"
Move-Dart "Views/Widgets/Marketing/AsyncButtons.dart"    "features/marketing/widgets/async_buttons.dart"

# operations + mf_transaction (sub-feature)
Move-Dart "API/operations_apiService.dart"                               "features/operations/api/operations_api_service.dart"
Move-Dart "Views/Screens/MFTransaction/MFTransScreen.dart"              "features/operations/mf_transaction/screens/mf_trans_screen.dart"
Move-Dart "Views/Screens/MFTransaction/MFTransFormScreen.dart"          "features/operations/mf_transaction/screens/mf_trans_form_screen.dart"
Move-Dart "Views/Screens/MFTransaction/MFTransReviewScreen.dart"        "features/operations/mf_transaction/screens/mf_trans_review_screen.dart"
Move-Dart "Views/Screens/MFTransaction/MFTransCompletedScreen.dart"     "features/operations/mf_transaction/screens/mf_trans_completed_screen.dart"
Move-Dart "ViewModels/mfTransForm_viewModel.dart"                        "features/operations/mf_transaction/view_models/mf_trans_form_view_model.dart"
Move-Dart "ViewModels/mfTransaction_viewModel.dart"                      "features/operations/mf_transaction/view_models/mf_transaction_view_model.dart"
Move-Dart "Models/mftrans_models.dart"                                   "features/operations/mf_transaction/models/mf_trans_models.dart"
Move-Dart "Views/Widgets/MFTrans/SwitchForm.dart"                       "features/operations/mf_transaction/widgets/switch_form.dart"
Move-Dart "Views/Widgets/MFTrans/SystematicForm.dart"                   "features/operations/mf_transaction/widgets/systematic_form.dart"
Move-Dart "Views/Widgets/MFTrans/UccCard.dart"                          "features/operations/mf_transaction/widgets/ucc_card.dart"
Move-Dart "Views/Widgets/MFTrans/formComponents.dart"                   "features/operations/mf_transaction/widgets/form_components.dart"
Move-Dart "Views/Widgets/MFTrans/mfTrans_common_widgets.dart"           "features/operations/mf_transaction/widgets/mf_trans_common_widgets.dart"
Move-Dart "Views/Widgets/MFTrans/purchRedemptionForm.dart"              "features/operations/mf_transaction/widgets/purch_redemption_form.dart"

# investwell_report
Move-Dart "Views/Screens/InvestwellReportScreen.dart"       "features/investwell_report/screens/investwell_report_screen.dart"
Move-Dart "ViewModels/investwellReport_viewModel.dart"      "features/investwell_report/view_models/investwell_report_view_model.dart"
Move-Dart "Models/investwell_report_models.dart"            "features/investwell_report/models/investwell_report_models.dart"

# route_management
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

# app_store
Move-Dart "Views/Screens/StoreScreen.dart"             "features/app_store/screens/store_screen.dart"
Move-Dart "ViewModels/appCard_viewModel.dart"           "features/app_store/view_models/app_card_view_model.dart"
Move-Dart "Models/appModel.dart"                        "features/app_store/models/app_model.dart"
Move-Dart "Providers/app_provider.dart"                 "features/app_store/providers/app_provider.dart"
Move-Dart "Providers/download_state_provider.dart"      "features/app_store/providers/download_state_provider.dart"
Move-Dart "Views/Widgets/AppStore/appCard.dart"         "features/app_store/widgets/app_card.dart"
Move-Dart "Views/Widgets/AppStore/download_button.dart" "features/app_store/widgets/download_button.dart"

# modules
Move-Dart "Views/Screens/ModuleScreen.dart"         "features/modules/screens/module_screen.dart"
Move-Dart "Models/moduleScreen_data.dart"            "features/modules/models/module_screen_data.dart"
Move-Dart "Utils/ModuleTransitionAnimation.dart"    "features/modules/utils/module_transition_animation.dart"
Move-Dart "Views/Widgets/api_error_state_view.dart" "features/modules/widgets/api_error_state_view.dart"

Write-Host "`n=== File moves complete ===" -ForegroundColor Green
