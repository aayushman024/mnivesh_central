import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:mnivesh_central/Themes/AppTextStyle.dart';
import '../Widgets/homeAppBar.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        HomeSliverAppBar(),
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    height: MediaQuery.of(context).size.width*0.4,
                    child: Lottie.asset("assets/Maintenance.json")),
                Padding(
                  padding:const EdgeInsets.only(top: 30),
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