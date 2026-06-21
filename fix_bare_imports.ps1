# ============================================================
# Fix bare filename imports (no directory prefix)
# These existed as co-located sibling imports in old structure
# ============================================================

$lib = "lib"
$pkg = "mnivesh_central"

# Bare filename → new package path
$bareMap = [ordered]@{
    # Previously in API/ (sibling imports within API/)
    "'api_client.dart'"   = "'package:$pkg/core/api/api_client.dart'"
    '"api_client.dart"'   = '"package:' + $pkg + '/core/api/api_client.dart"'
    "'api_config.dart'"   = "'package:$pkg/core/api/api_config.dart'"
    '"api_config.dart"'   = '"package:' + $pkg + '/core/api/api_config.dart"'
    "'api_service.dart'"  = "'package:$pkg/core/api/api_service.dart'"
    '"api_service.dart"'  = '"package:' + $pkg + '/core/api/api_service.dart"'

    # Previously in Services/
    "'snackBar_Service.dart'"   = "'package:$pkg/core/services/snack_bar_service.dart'"
    '"snackBar_Service.dart"'   = '"package:' + $pkg + '/core/services/snack_bar_service.dart"'

    # Previously in Managers/ (sibling imports)
    "'AuthManager.dart'"            = "'package:$pkg/features/auth/managers/auth_manager.dart'"
    '"AuthManager.dart"'            = '"package:' + $pkg + '/features/auth/managers/auth_manager.dart"'
    "'ChildSsoRequestHandler.dart'" = "'package:$pkg/features/auth/managers/child_sso_request_handler.dart'"
    '"ChildSsoRequestHandler.dart"' = '"package:' + $pkg + '/features/auth/managers/child_sso_request_handler.dart"'

    # Previously in ViewModels/ (sibling imports)
    "'mfTransaction_viewModel.dart'" = "'package:$pkg/features/operations/mf_transaction/view_models/mf_transaction_view_model.dart'"
    '"mfTransaction_viewModel.dart"' = '"package:' + $pkg + '/features/operations/mf_transaction/view_models/mf_transaction_view_model.dart"'

    # Previously in Utils/ (sibling imports)
    "'marketing_image_util.dart'"   = "'package:$pkg/features/marketing/utils/marketing_image_util.dart'"
    '"marketing_image_util.dart"'   = '"package:' + $pkg + '/features/marketing/utils/marketing_image_util.dart"'
}

$dartFiles = Get-ChildItem -Path $lib -Recurse -Filter "*.dart"
Write-Host ('Found ' + $dartFiles.Count + ' dart files') -ForegroundColor Cyan

$updated = 0
foreach ($file in $dartFiles) {
    $lines = Get-Content $file.FullName -Encoding UTF8
    $changed = $false
    $newLines = foreach ($line in $lines) {
        if ($line -match "import") {
            $newLine = $line
            foreach ($key in $bareMap.Keys) {
                if ($newLine.Contains($key)) {
                    $newLine = $newLine.Replace($key, $bareMap[$key])
                    $changed = $true
                }
            }
            $newLine
        } else {
            $line
        }
    }
    if ($changed) {
        Set-Content -Path $file.FullName -Value $newLines -Encoding UTF8
        Write-Host ('  [FIXED] ' + $file.Name) -ForegroundColor Green
        $updated++
    }
}

Write-Host ('Bare import fix complete - ' + $updated + ' files updated.') -ForegroundColor Cyan
