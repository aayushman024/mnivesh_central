import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Themes/AppTextStyle.dart';

class HomeSliverAppBar extends ConsumerStatefulWidget {
  final String storeName;

  const HomeSliverAppBar({
    super.key,
    this.storeName = "mNivesh Central",
  });

  @override
  ConsumerState<HomeSliverAppBar> createState() => _HomeSliverAppBarState();
}

class _HomeSliverAppBarState extends ConsumerState<HomeSliverAppBar>
    with WidgetsBindingObserver {
  String _greeting = "";
  String _userName = "User!";

  // Consts for consistent spacing
  static const double _expandedHeight = 130.0;
  static const double _collapsedHeight = kToolbarHeight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateGreeting();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _userName = prefs.getString('UserName') ?? "User!");
    }
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
      _loadUserName();
    }
  }

  void _updateGreeting() {
    final hour = DateTime.now().hour;
    setState(() {
      if (hour >= 4 && hour < 12) _greeting = "Good Morning, ☀️";
      else if (hour >= 12 && hour < 16) _greeting = "Good Afternoon, 🌤️";
      else _greeting = "Good Evening, 🌙";
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topPadding = MediaQuery.paddingOf(context).top;

    return SliverAppBar(
      expandedHeight: _expandedHeight,
      collapsedHeight: _collapsedHeight,
      pinned: true,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false, // Handle leading manually for custom placement
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent, // Prevents tint change on scroll

      // Fixed Menu Button
      leading: IconButton(
        icon: Icon(PhosphorIcons.userCircle(), color: theme.colorScheme.onSurface),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),

      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double currentHeight = constraints.biggest.height;
          // Calculate 0.0 to 1.0 progress (1.0 = expanded, 0.0 = collapsed)
          final double t = ((currentHeight - _collapsedHeight - topPadding) /
              (_expandedHeight - _collapsedHeight - topPadding)).clamp(0.0, 1.0);

          // Interpolation values
          final double leftOffset = Tween<double>(begin: 72.0, end: 20.0).transform(t);
          final double topOffset = Tween<double>(
            begin: topPadding + 14.0,
            end: currentHeight - 65.0,
          ).transform(t);
          final double fontSizeScale = Tween<double>(begin: 0.85, end: 1.0).transform(t);

          return Stack(
            children: [
              Positioned(
                top: topOffset,
                left: leftOffset,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Greeting fades out as we collapse
                    Opacity(
                      opacity: (t *3 - 1.5).clamp(0.0, 1.0),
                      child: Visibility(
                        visible: t > 0.5,
                        child: Text(
                          _greeting,
                          style: AppTextStyle.normal.small(
                            theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        ),
                      ),
                    ),
                    // Name morphs into the "Title" position
                    Transform.scale(
                      scale: fontSizeScale,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _userName,
                        style: AppTextStyle.bold.large(theme.textTheme.bodyLarge?.color),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}