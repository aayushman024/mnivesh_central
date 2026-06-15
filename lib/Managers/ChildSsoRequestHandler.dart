import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'AuthManager.dart';

class ChildSsoRequestHandler {
  static Future<bool> handle(Uri uri, BuildContext context) async {
    if (uri.host != 'sso' || uri.path != '/request') {
      return false;
    }

    debugPrint("[SSO] Received SSO Request.");

    try {
      final callbackUrlString = uri.queryParameters['callback'];
      if (callbackUrlString == null || callbackUrlString.isEmpty) {
        debugPrint("[SSO] Error: 'callback' parameter is missing.");
        return true;
      }

      final parsedCallback = Uri.tryParse(callbackUrlString);
      if (parsedCallback == null) {
        debugPrint("[SSO] Error: Invalid callback URI format: $callbackUrlString");
        return true;
      }

      // Check if user is logged in
      final accessToken = AuthManager.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        debugPrint("[SSO] User NOT logged in. Returning error immediately.");
        final newParams = Map<String, String>.from(parsedCallback.queryParameters);
        newParams['error'] = 'not_logged_in';
        final redirectUri = parsedCallback.replace(queryParameters: newParams);
        debugPrint("[SSO] Redirecting to: $redirectUri");
        await launchUrl(redirectUri, mode: LaunchMode.externalApplication);
        return true;
      }

      // Extract app name
      String appName = parsedCallback.scheme.toUpperCase();
      if (parsedCallback.scheme == 'http' || parsedCallback.scheme == 'https') {
        final host = parsedCallback.host;
        if (host.isNotEmpty) {
          final parts = host.split('.');
          if (parts.length > 1) {
            appName = parts[parts.length - 2].toUpperCase();
          } else {
            appName = host.toUpperCase();
          }
        }
      }

      // Show bottom sheet
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isDismissible: false,
          enableDrag: false,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) => SsoAuthorizationBottomSheet(
            appName: appName,
            onCancel: () {
              Navigator.pop(sheetContext);
              debugPrint("[SSO] User cancelled login request.");
            },
            onConfirm: (data) async {
              Navigator.pop(sheetContext);
              debugPrint("[SSO] User approved login request. Fetching tokens...");
              
              // Hydrate latest data before redirecting to avoid stale tokens
              await AuthManager.hydrate();
              final latestAccessToken = AuthManager.accessToken;
              final latestRefreshToken = AuthManager.refreshToken;
              final latestTokenType = AuthManager.tokenType;
              final latestKid = AuthManager.kid;

              if (latestAccessToken == null || latestAccessToken.isEmpty) {
                debugPrint("[SSO] Error: Latest tokens are missing after confirmation.");
                return;
              }

              final newParams = Map<String, String>.from(parsedCallback.queryParameters);
              newParams.addAll({
                'accessToken': latestAccessToken,
                'tokenType': latestTokenType ?? 'Bearer',
              });

              if (latestRefreshToken != null && latestRefreshToken.isNotEmpty) {
                newParams['refreshToken'] = latestRefreshToken;
              }
              if (latestKid != null && latestKid.isNotEmpty) {
                newParams['kid'] = latestKid;
              }

              final name = data['name'] ?? '';
              final email = data['email'] ?? '';
              final phone = data['phone'] ?? '';
              final dept = data['dept'] ?? '';

              if (name.trim().isNotEmpty) {
                newParams['name'] = name.trim();
              }
              if (email.trim().isNotEmpty) {
                newParams['email'] = email.trim();
              }
              if (dept.trim().isNotEmpty) {
                newParams['departmentName'] = dept.trim();
              }
              if (phone.trim().isNotEmpty) {
                newParams['associatedNumber'] = phone.trim();
              }

              final redirectUri = parsedCallback.replace(queryParameters: newParams);
              debugPrint("[SSO] Redirecting to child app: $redirectUri");
              await launchUrl(redirectUri, mode: LaunchMode.externalApplication);
            },
          ),
        );
      }

    } catch (e) {
      debugPrint("[SSO] Critical Error handling SSO request: $e");
    }

    return true;
  }
}

class SsoAuthorizationBottomSheet extends StatefulWidget {
  final String appName;
  final VoidCallback onCancel;
  final Function(Map<String, String> data) onConfirm;

  const SsoAuthorizationBottomSheet({
    super.key,
    required this.appName,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  State<SsoAuthorizationBottomSheet> createState() => _SsoAuthorizationBottomSheetState();
}

class _SsoAuthorizationBottomSheetState extends State<SsoAuthorizationBottomSheet> {
  bool _isLoading = true;
  String _name = '';
  String _email = '';
  String _phone = '';
  String _dept = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Hydrate tokens and read user details from SharedPreferences
    await AuthManager.hydrate();
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _name = prefs.getString('UserName') ?? '';
        _email = prefs.getString('UserEmail') ?? '';
        _phone = prefs.getString('workPhone') ?? '';
        _dept = prefs.getString('user_department') ?? '';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Authorize ${widget.appName}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.appName} is requesting to access your mNivesh Central account. Your name, email, alloted number, and other fields will be shared.',
            style: TextStyle(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Skeletonizer(
            enabled: _isLoading,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Name', _name.trim().isNotEmpty ? _name : 'N/A'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Email', _email.trim().isNotEmpty ? _email : 'N/A'),
                  const SizedBox(height: 12),
                  _buildDetailRow('Phone', _phone.trim().isNotEmpty ? _phone : 'N/A'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              TextButton(
                onPressed: widget.onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text(
                  "Don't Allow",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        widget.onConfirm({
                          'name': _name,
                          'email': _email,
                          'phone': _phone,
                          'dept': _dept,
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Continue to Login',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
