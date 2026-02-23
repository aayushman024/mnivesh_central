import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../Providers/app_provider.dart';
import '../../Themes/AppTextStyle.dart';

class HomeSliverAppBar extends ConsumerStatefulWidget {
  final String userName;
  final String storeName;

  const HomeSliverAppBar({
    super.key,
    this.userName = "User!",
    this.storeName = "mNivesh Central",
  });

  @override
  ConsumerState<HomeSliverAppBar> createState() => _HomeSliverAppBarState();
}

class _HomeSliverAppBarState extends ConsumerState<HomeSliverAppBar> with WidgetsBindingObserver {
  String _greeting = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateGreeting();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateGreeting();
    }
  }

  void _updateGreeting() {
    setState(() {
      _greeting = _getGreeting();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) return "Good Morning, ☀️";
    if (hour >= 12 && hour < 16) return "Good Afternoon, 🌤️";
    return "Good Evening, 🌙";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SliverAppBar(
      expandedHeight: 140.0,
      pinned: true,
      floating: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,

      // FIX: Added IconButton to open the drawer
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            icon: Icon(
              Icons.menu_rounded, // Rounded menu icon looks cleaner
              color: colorScheme.onSurface, // Adapts to Dark/Light mode
            ),
            onPressed: () {
              // This finds the Scaffold in HomePage and opens the endDrawer
              Scaffold.of(context).openEndDrawer();
            },
          ),
        ),
      ],

      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        expandedTitleScale: 1.5,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              _greeting,
              style: AppTextStyle.normal.small(
                  theme.textTheme.bodySmall?.color?.withOpacity(0.6)
              ).copyWith(fontSize: 10),
            ),
            const SizedBox(height: 2),
            Text(
              widget.userName,
              style: AppTextStyle.bold.normal(theme.textTheme.bodyLarge?.color),
            ),
          ],
        ),
      ),
    );
  }
}