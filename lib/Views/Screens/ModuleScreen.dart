import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../Utils/Dimensions.dart';
import '../Widgets/homeAppBar.dart';
import '../Widgets/neumorphic_button.dart';

class ModulesScreen extends StatelessWidget {
  const ModulesScreen({super.key});

  int _getColumnCount(double width) {
    if (width >= 1200) return 6;
    if (width >= 900) return 5;
    if (width >= 600) return 4;
    return 3;
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Coming soon!"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: EdgeInsets.all(16.sdp),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.sdp),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double spacing = 20.sdp;
    final double padding = 20.sdp;
    final double screenWidth = MediaQuery.of(context).size.width;

    final int crossAxisCount = _getColumnCount(screenWidth);

    return CustomScrollView(
      slivers: [
        const HomeSliverAppBar(),

        SliverPadding(
          padding: EdgeInsets.all(padding),

          sliver: SliverGrid(
            delegate: SliverChildListDelegate([

              NeumorphicModuleButton(
                title: "MF Trans",
                icon: PhosphorIconsRegular.arrowsLeftRight,
                onTap: (){
                  _showComingSoon(context);
                },
              ),

            ]),

            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,

              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              mainAxisExtent: 140,
            ),
          ),
        ),
      ],
    );
  }
}