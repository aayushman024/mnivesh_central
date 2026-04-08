import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Themes/AppTextStyle.dart';
import '../../Utils/Dimensions.dart';

class HomeSliverAppBar extends ConsumerStatefulWidget {
  const HomeSliverAppBar({super.key});

  @override
  ConsumerState<HomeSliverAppBar> createState() => _HomeSliverAppBarState();
}

class _HomeSliverAppBarState extends ConsumerState<HomeSliverAppBar>
    with WidgetsBindingObserver {
  String _greeting = "";
  String _userName = "User!";

  // Consts for consistent spacing
  static const double _expandedHeight = 140.0;
  static const double _collapsedHeight = kToolbarHeight + 15;

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
      if (hour >= 4 && hour < 12) {
        _greeting = "Good Morning, ☀️";
      } else if (hour >= 12 && hour < 16)
        _greeting = "Good Afternoon, 🌤️";
      else
        _greeting = "Good Evening, 🌙";
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
      centerTitle: false,
      automaticallyImplyLeading: true,
      // Handle leading manually for custom placement
      backgroundColor: theme.scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      // Prevents tint change on scroll

      // Fixed Menu Button
      leading: Container(
        margin: EdgeInsets.only(top: 18.sdp, left: 18.sdp),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.sdp),
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white10 : Colors.grey.shade300,
        ),
        child: IconButton(
        icon: Icon(
          PhosphorIcons.userCircle(PhosphorIconsStyle.fill),
          color: theme.colorScheme.onSurface,
        ),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
      ),

      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final double currentHeight = constraints.biggest.height;

          // Fixed progress calculation to map scroll height accurately
          final double scrollRange = _expandedHeight - _collapsedHeight;
          final double t =
              ((currentHeight - _collapsedHeight - topPadding) / scrollRange)
                  .clamp(0.0, 1.0);

          // Curve the horizontal movement so text dodges the leading icon earlier
          final double curvedT = Curves.easeOut.transform(t);
          final double leftOffset = Tween<double>(
            begin: 72.0,
            end: 20.0,
          ).transform(curvedT);

          // Position elements independently to prevent layout snaps when greeting hides
          final double nameTop = Tween<double>(
            begin: topPadding + 16.0,
            // Centered vertically in collapsed toolbar
            end: currentHeight - 40.0,
          ).transform(t);

          final double greetingTop = Tween<double>(
            begin: topPadding + 0.0, // Pushes up and out of the way
            end: currentHeight - 65.0,
          ).transform(t);

          final double fontSizeScale = Tween<double>(
            begin: 0.85,
            end: 1.0,
          ).transform(t);

          // Fade out smoothly in the first 50% of the collapse
          final double greetingOpacity = (t * 2 - 1.0).clamp(0.0, 1.0);

          return Stack(
            children: [
              // Greeting
              Positioned(
                top: greetingTop,
                left: leftOffset,
                child: Opacity(
                  opacity: greetingOpacity,
                  child: Text(
                    _greeting,
                    style: AppTextStyle.normal.small(
                      theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
              // Username
              Positioned(
                top: nameTop,
                left: leftOffset,
                child: Transform.scale(
                  scale: fontSizeScale,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _userName,
                    style: AppTextStyle.extraBold.large(
                      theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(top: 18.sdp, right: 18.sdp),
          child: Badge(
            isLabelVisible:
                true, // Hardcoded for now, will wire up with API later
            label: Text("2", style: AppTextStyle.normal.custom(11.ssp)),
            //label: Container(color: Colors.red, height: 12.sdp,),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.sdp),
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10 : Colors.grey.shade300,
              ),
              child: IconButton(
                tooltip: "Notifications",
                onPressed: () {},
                icon: Icon(PhosphorIcons.bell(
                  PhosphorIconsStyle.fill
                )),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
