import 'package:flutter/material.dart';
import '../Widgets/homeAppBar.dart';

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      slivers: [
        HomeSliverAppBar(userName: "Aayushman Ranjan", storeName: "mNivesh Central"),
        SliverFillRemaining(
          child: Center(
            child: Text(
              "Modules - Under Development",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }
}