import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../Themes/AppTextStyle.dart';
import '../../Utils/Dimensions.dart';
import '../Widgets/homeAppBar.dart';

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const HomeSliverAppBar(),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    height: MediaQuery.of(context).size.width*0.4,
                    child: Lottie.asset("assets/Maintenance.json")),
                Padding(
                  padding: EdgeInsets.only(top:30.sdp),
                  child: Text("UNDER DEVELOPMENT",
                      style: AppTextStyle.bold.normal(
                      ).copyWith(letterSpacing: 2)),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}