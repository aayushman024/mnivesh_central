import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../Services/snackBar_Service.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';
import '../../Widgets/ModuleAppBar.dart';

class RouteManagementDashboard extends StatelessWidget {
  const RouteManagementDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModuleAppBar(title: "Route Management"),
      body: Column(
        children: [
          SizedBox(height: 8.sdp),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? colorScheme.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32.sdp),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 24.sdp,
                    offset: Offset(0, -4.sdp),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(32.sdp),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = _getColumnCount(
                      constraints.maxWidth,
                    );

                    return GridView.builder(
                      padding: EdgeInsets.fromLTRB(
                        20.sdp,
                        28.sdp,
                        20.sdp,
                        40.sdp,
                      ),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16.sdp,
                        mainAxisSpacing: 16.sdp,
                        mainAxisExtent: crossAxisCount == 1 ? 170.sdp : 150.sdp,
                      ),
                      itemCount: _routeOptions.length,
                      itemBuilder: (context, index) {
                        return _RouteOptionCard(option: _routeOptions[index]);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getColumnCount(double width) {
    if (width >= 1100) return 3;
    if (width >= 700) return 2;
    return 1;
  }
}

class _RouteOptionCard extends StatelessWidget {
  final _RouteDashboardOption option;

  const _RouteOptionCard({required this.option});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isHighlighted = option.isHighlighted;

    final backgroundDecoration = isHighlighted
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDark ? const Color(0xFF1A2742) : const Color(0xFF101C34),
                Color.lerp(
                  isDark ? const Color(0xFF1A2742) : const Color(0xFF101C34),
                  option.accent,
                  isDark ? 0.24 : 0.18,
                )!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24.sdp),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          )
        : BoxDecoration(
            color: isDark
                ? Color.lerp(colorScheme.surface, Colors.white, 0.06)
                : theme.cardTheme.color ?? colorScheme.surface,
            borderRadius: BorderRadius.circular(24.sdp),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : colorScheme.outline.withValues(alpha: 0.12),
            ),
          );

    final titleColor = isHighlighted ? Colors.white : colorScheme.onSurface;
    final bodyColor = isHighlighted
        ? Colors.white.withValues(alpha: 0.76)
        : colorScheme.onSurface.withValues(alpha: 0.64);
    final iconBgColor = isHighlighted
        ? option.accent.withValues(alpha: 0.12)
        : option.accent.withValues(alpha: 0.10);
    final tagBgColor = isHighlighted
        ? option.accent.withValues(alpha: 0.16)
        : option.accent.withValues(alpha: 0.10);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: SnackbarService.showComingSoon,
        borderRadius: BorderRadius.circular(24.sdp),
        child: Ink(
          decoration: backgroundDecoration,
          child: Padding(
            padding: EdgeInsets.all(20.sdp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42.sdp,
                      height: 42.sdp,
                      decoration: BoxDecoration(
                        color: iconBgColor,
                        borderRadius: BorderRadius.circular(14.sdp),
                      ),
                      child: Icon(
                        option.icon(),
                        color: option.accent,
                        size: 20.sdp,
                      ),
                    ),
                    SizedBox(width: 12.sdp),
                    Expanded(
                      child: Text(
                        option.title,
                        style: AppTextStyle.extraBold.custom(
                          16.ssp,
                          titleColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8.sdp),
                    _RouteTag(
                      label: option.tag,
                      textColor: option.accent,
                      backgroundColor: tagBgColor,
                    ),
                  ],
                ),
                SizedBox(height: 14.sdp),
                Expanded(
                  child: Text(
                    option.description,
                    style: AppTextStyle.normal
                        .custom(13.ssp, bodyColor)
                        .copyWith(height: 1.7),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 4.sdp),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteTag extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;

  const _RouteTag({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sdp, vertical: 7.sdp),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999.sdp),
      ),
      child: Text(
        label,
        style: AppTextStyle.bold
            .custom(11.ssp, textColor)
            .copyWith(letterSpacing: 1.4),
      ),
    );
  }
}

class _RouteDashboardOption {
  final String title;
  final String description;
  final String tag;
  final PhosphorIconData Function([PhosphorIconsStyle]) icon;
  final Color accent;
  final bool isHighlighted;

  const _RouteDashboardOption({
    required this.title,
    required this.description,
    required this.tag,
    required this.icon,
    required this.accent,
    this.isHighlighted = false,
  });
}

const List<_RouteDashboardOption> _routeOptions = [
  _RouteDashboardOption(
    title: 'Track Field Executive',
    description:
        'Monitor real-time locations and delays across your field force to keep the day on track.',
    tag: 'LIVE',
    icon: PhosphorIcons.mapPinLine,
    accent: Color(0xFF38D39F),
    isHighlighted: true,
  ),
  _RouteDashboardOption(
    title: 'Add New Client Visit',
    description:
        'Capture upcoming meetings, preferred timeslots and visit objectives in just a few clicks.',
    tag: 'PIPELINE',
    icon: PhosphorIcons.plusCircle,
    accent: Color(0xFF5ED6A8),
  ),
  _RouteDashboardOption(
    title: 'Show Assigned Details',
    description:
    'See a consolidated view of which executive owns which clients, upcoming visits and status.',
    tag: 'OVERVIEW',
    icon: PhosphorIcons.bookmarkSimple,
    accent: Color(0xFF42C7D6),
  ),
  _RouteDashboardOption(
    title: 'Show Unassigned Client',
    description:
        'Review all clients that are pending assignment and quickly move them into an FE\'s queue.',
    tag: 'BACKLOG',
    icon: PhosphorIcons.briefcase,
    accent: Color(0xFFFFB547),
  ),
  _RouteDashboardOption(
    title: 'Show On-Hold Clients',
    description:
        'Track temporarily paused visits and decide when to reactivate visits or follow-ups.',
    tag: 'STATUS',
    icon: PhosphorIcons.pauseCircle,
    accent: Color(0xFFE266FF),
  ),
  _RouteDashboardOption(
    title: 'Create Temporary Client',
    description:
        'Add temporary clients, define coverage regions and manage their activity status.',
    tag: 'SETUP',
    icon: PhosphorIcons.userCirclePlus,
    accent: Color(0xFF4DB8FF),
  ),
];
