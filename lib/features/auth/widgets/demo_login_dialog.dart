import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mnivesh_central/core/theme/app_text_style.dart';
import 'package:mnivesh_central/core/utils/dimensions.dart';
import 'package:mnivesh_central/features/auth/demo/demo_constants.dart';
import 'package:mnivesh_central/features/auth/demo/demo_mode_provider.dart';
import 'package:mnivesh_central/features/auth/managers/auth_manager.dart';
import 'package:mnivesh_central/features/home/screens/main_screen.dart';

/// A dialog that lets app store reviewers log in with a hardcoded demo account.
///
/// Credentials: [DemoConstants.email] / [DemoConstants.password]
/// On success:  sets [demoModeProvider] = true and navigates to [MainScreen].
class DemoLoginDialog extends ConsumerStatefulWidget {
  const DemoLoginDialog({super.key});

  /// Convenience method — shows the dialog and awaits its result.
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      // useSafeArea ensures the dialog respects the keyboard insets
      useSafeArea: true,
      builder: (_) => const DemoLoginDialog(),
    );
  }

  @override
  ConsumerState<DemoLoginDialog> createState() => _DemoLoginDialogState();
}

class _DemoLoginDialogState extends ConsumerState<DemoLoginDialog> {
  final _formKey = GlobalKey<FormState>();
  // No pre-fill — reviewer types the credentials themselves
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _credentialError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Clear any previous credential error first
    setState(() => _credentialError = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final enteredEmail = _emailController.text.trim().toLowerCase();
    final enteredPassword = _passwordController.text;

    // Hardcoded credential check
    if (enteredEmail != DemoConstants.email ||
        enteredPassword != DemoConstants.password) {
      setState(() {
        _credentialError = 'Incorrect username or password. Please try again.';
      });
      return;
    }

    setState(() => _isLoading = true);

    // Brief pause so the transition feels intentional
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    // Activate demo mode — gates all API calls across the app
    ref.read(demoModeProvider.notifier).state = true;
    AuthManager.isDemoMode = true; // guards AuthInterceptor from 401 → logout

    // Navigate to MainScreen, clearing the entire navigation stack
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0);
    final labelColor = isDark ? Colors.white70 : const Color(0xFF475569);
    final hintColor = isDark ? Colors.white30 : Colors.black26;
    final inputFillColor =
        isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC);

    final mq = MediaQuery.of(context);
    final keyboardHeight = mq.viewInsets.bottom;
    final screenHeight = mq.size.height;
    // Cap dialog height so it never exceeds the space above the keyboard.
    // 120 = top safe area + outer top/bottom margins (2 × 40) padding
    final maxDialogHeight = screenHeight - keyboardHeight - 120;

    return Dialog(
      backgroundColor: surfaceColor,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.sdp, vertical: 40.sdp),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.sdp),
        side: BorderSide(color: borderColor),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxDialogHeight),
        child: SingleChildScrollView(
        padding: EdgeInsets.all(24.sdp),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.sdp),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C4DFF).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12.sdp),
                    ),
                    child: const Icon(
                      Icons.play_circle_outline_rounded,
                      color: Color(0xFF7C4DFF),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12.sdp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Demo Mode',
                          style: AppTextStyle.extraBold
                              .normal(
                                isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              )
                              .copyWith(fontSize: 18.ssp),
                        ),
                        Text(
                          'Explore the app as a guest',
                          style: AppTextStyle.normal.small(labelColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24.sdp),

              // ── Username field ─────────────────────────────────────────────
              Text(
                'Username',
                style: AppTextStyle.normal
                    .small(labelColor)
                    .copyWith(fontSize: 13.ssp),
              ),
              SizedBox(height: 6.sdp),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                style: AppTextStyle.normal.normal(
                  isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: _inputDecoration(
                  hint: 'Enter username',
                  icon: Icons.person_outline_rounded,
                  fillColor: inputFillColor,
                  borderColor: borderColor,
                  hintColor: hintColor,
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return 'Username is required';
                  if (!v.contains('@')) return 'Enter a valid email address';
                  return null;
                },
              ),

              SizedBox(height: 16.sdp),

              // ── Password field ─────────────────────────────────────────────
              Text(
                'Password',
                style: AppTextStyle.normal
                    .small(labelColor)
                    .copyWith(fontSize: 13.ssp),
              ),
              SizedBox(height: 6.sdp),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                style: AppTextStyle.normal.normal(
                  isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: _inputDecoration(
                  hint: 'Enter password',
                  icon: Icons.lock_outline_rounded,
                  fillColor: inputFillColor,
                  borderColor: borderColor,
                  hintColor: hintColor,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: labelColor,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) {
                  if ((value ?? '').isEmpty) return 'Password is required';
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),

              // ── Credential error ───────────────────────────────────────────
              if (_credentialError != null) ...[
                SizedBox(height: 10.sdp),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 16,
                    ),
                    SizedBox(width: 6.sdp),
                    Expanded(
                      child: Text(
                        _credentialError!,
                        style: AppTextStyle.normal
                            .small(const Color(0xFFEF4444))
                            .copyWith(fontSize: 12.ssp),
                      ),
                    ),
                  ],
                ),
              ],

              SizedBox(height: 24.sdp),

              // ── Actions ────────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.sdp),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.sdp),
                          side: BorderSide(color: borderColor),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyle.normal.normal(labelColor),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.sdp),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.sdp),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.sdp),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20.sdp,
                              height: 20.sdp,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Enter Demo',
                              style: AppTextStyle.bold.normal(Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ), // ConstrainedBox
  );
  } // end build

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required Color fillColor,
    required Color borderColor,
    required Color hintColor,
    Widget? suffix,
  }) {
    final outlineBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.sdp),
      borderSide: BorderSide(color: borderColor),
    );
    final focusBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.sdp),
      borderSide: const BorderSide(color: Color(0xFF7C4DFF), width: 1.5),
    );
    final errorBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.sdp),
      borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
    );

    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyle.normal.small(hintColor),
      prefixIcon: Icon(icon, size: 20, color: hintColor),
      suffixIcon: suffix,
      filled: true,
      fillColor: fillColor,
      border: outlineBorder,
      enabledBorder: outlineBorder,
      focusedBorder: focusBorder,
      errorBorder: errorBorder,
      focusedErrorBorder: errorBorder,
      contentPadding:
          EdgeInsets.symmetric(horizontal: 16.sdp, vertical: 14.sdp),
      errorStyle: AppTextStyle.normal
          .small(const Color(0xFFEF4444))
          .copyWith(fontSize: 11.ssp),
    );
  }
}
