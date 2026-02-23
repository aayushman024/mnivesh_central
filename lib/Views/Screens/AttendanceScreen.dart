import 'package:flutter/material.dart';
import '../Widgets/homeAppBar.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        HomeSliverAppBar(userName: "Aayushman Ranjan", storeName: "mNivesh Central"),
        SliverFillRemaining(
          child: Center(
            child: Text(
              "Attendance - Under Development",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}