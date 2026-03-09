// lib/Views/Screens/ModulesScreens/MFTransCompletedScreen.dart

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mnivesh_central/Views/Screens/MainScreen.dart';

import '../../../../Themes/AppTextStyle.dart';
import '../../../../Utils/Dimensions.dart';
import 'MFTransScreen.dart';

class MFTransCompletedScreen extends StatelessWidget {
  const MFTransCompletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.sdp, vertical: 24.sdp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Success Animation
              Lottie.asset(
                'assets/Success.json',
                width: 150.sdp,
                height: 150.sdp,
                repeat: false,
              ),
              SizedBox(height: 32.sdp),

              Text(
                'Transaction Form Submitted Successfully',
                textAlign: TextAlign.center,
                style: AppTextStyle.bold
                    .large(colorScheme.onSurface)
                    .copyWith(fontSize: 20.ssp),
              ),
              SizedBox(height: 16.sdp),

              Text(
                'Your mutual fund transaction request has been recorded and forwarded to the operations workflow for further processing.',
                textAlign: TextAlign.center,
                style: AppTextStyle.normal
                    .small(colorScheme.onSurface.withOpacity(0.6))
                    .copyWith(fontSize: 14.ssp, height: 1.5),
              ),

              const Spacer(),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 48.sdp,
                child: ElevatedButton(
                  onPressed: () {
                    // clear stack and go to modules
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(pageIndex: 1),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.sdp),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'GO MAIN MENU',
                    style: AppTextStyle.bold
                        .normal(colorScheme.onPrimary)
                        .copyWith(fontSize: 14.ssp),
                  ),
                ),
              ),
              SizedBox(height: 16.sdp),

              SizedBox(
                width: double.infinity,
                height: 48.sdp,
                child: OutlinedButton(
                  onPressed: () {
                    // replace current with fresh mftrans screen
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const MfTransactionScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.sdp),
                    ),
                  ),
                  child: Text(
                    'ADD ANOTHER TRANSACTION',
                    style: AppTextStyle.bold
                        .normal(colorScheme.primary)
                        .copyWith(fontSize: 14.ssp),
                  ),
                ),
              ),
              SizedBox(height: 16.sdp),
            ],
          ),
        ),
      ),
    );
  }
}
