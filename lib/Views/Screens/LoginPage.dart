import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../Themes/AppTextStyle.dart';
import '../../Utils/Dimensions.dart';
import '../../ViewModels/login_viewModel.dart';

class ZohoLoginScreen extends ConsumerStatefulWidget {
  const ZohoLoginScreen({super.key});

  @override
  ConsumerState<ZohoLoginScreen> createState() => _ZohoLoginScreenState();
}

class _ZohoLoginScreenState extends ConsumerState<ZohoLoginScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _enterAnimController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    // drive entrance animations
    _enterAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim = CurvedAnimation(
      parent: _enterAnimController,
      curve: Curves.easeOut,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterAnimController,
      curve: Curves.easeOutCubic,
    ));

    _enterAnimController.forward();
  }

  @override
  void dispose() {
    _enterAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // watching the loading state from our viewmodel
    final isLoading = ref.watch(loginViewModelProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF121218),
      body: Stack(
        children: [
          const AnimatedGradientBackground(),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24.0.sdp),
              child: Column(
                children: [
                  const Spacer(),

                  SlideTransition(
                    position: _slideAnim,
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/companyIcon.png',
                            height: 180.sdp,
                            width: 180.sdp,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: 14.sdp),
                          Image.asset(
                            'assets/mNiveshIcon.png',
                            height: 120.sdp,
                            width: 120.sdp,
                            fit: BoxFit.contain,
                          ),
                          SizedBox(height: 44.sdp),

                          Text(
                            "Welcome to",
                            style: AppTextStyle.light.large(
                                Colors.white.withOpacity(0.9)
                            ).copyWith(fontSize: 20.ssp, letterSpacing: 0.5),
                          ),
                          SizedBox(height: 18.sdp),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "mNivesh Central",
                                style: AppTextStyle.bold.large(Colors.white).copyWith(
                                  fontSize: 34.ssp,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.sdp),

                          Text(
                            "Your All-In-One App for managing your proffesional needs.",
                            textAlign: TextAlign.center,
                            style: AppTextStyle.normal.normal(
                                Colors.white.withOpacity(0.6)
                            ).copyWith(height: 1.5.sdp),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  SlideTransition(
                    position: Tween<Offset>(
                        begin: const Offset(0, 0.5),
                        end: Offset.zero
                    ).animate(CurvedAnimation(
                        parent: _enterAnimController,
                        curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic)
                    )),
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0, end: 1).animate(
                          CurvedAnimation(
                              parent: _enterAnimController,
                              curve: const Interval(0.3, 1.0)
                          )
                      ),
                      child: LoginButton(
                        isLoading: isLoading,
                        onTap: () => ref.read(loginViewModelProvider.notifier).handleLogin(),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.sdp),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedGradientBackground extends StatefulWidget {
  const AnimatedGradientBackground({super.key});

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              final angle = _bgController.value * 2 * math.pi;

              // orbit math for gradient blobs
              final x1 = (w / 2.5) * math.cos(angle);
              final y1 = (h / 3) * math.sin(angle);

              final x2 = (w / 2.5) * math.cos(angle + math.pi);
              final y2 = (h / 3) * math.sin(angle + math.pi);

              return Stack(
                children: [
                  Container(color: const Color(0xFF121218)),

                  Positioned(
                    left: (w / 2) - 200 + x1,
                    top: (h / 2) - 200 + y1,
                    child: Container(
                      width: 400.sdp,
                      height: 400.sdp,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFF7C4DFF).withOpacity(0.25),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    left: (w / 2) - 200 + x2,
                    top: (h / 2) - 200 + y2,
                    child: Container(
                      width: 400.sdp,
                      height: 400.sdp,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFF4081).withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              );
            },
          );
        }
    );
  }
}

class LoginButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const LoginButton({
    super.key,
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // strictly for visual scale anim
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),

      // real action logic here
      onTap: () {
        print("[UI] Button tapped!");
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: 60.sdp,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.sdp),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C4DFF).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ]
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
              width: 24.sdp,
              height: 24.sdp,
              child: const CircularProgressIndicator(
                color: Color(0xFF121218),
                strokeWidth: 2.5,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.login_rounded, color: Color(0xFF121218)),
                SizedBox(width: 12.sdp),
                Text(
                  "Continue with Zoho",
                  style: AppTextStyle.bold.normal(const Color(0xFF121218)).copyWith(
                    fontSize: 17.ssp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}