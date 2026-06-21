import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import 'package:mnivesh_central/core/services/snack_bar_service.dart';
import 'package:mnivesh_central/core/theme/app_text_style.dart';
import 'package:mnivesh_central/core/utils/dimensions.dart';
import 'package:mnivesh_central/features/route_management/screens/field_executive_tracking_screen.dart';
import 'package:mnivesh_central/features/route_management/screens/visit_details_screen.dart';
import 'package:mnivesh_central/features/route_management/screens/add_task_screen.dart';
import 'package:mnivesh_central/features/route_management/screens/view_route_details_screen.dart';
import 'package:mnivesh_central/features/route_management/widgets/module_app_bar.dart';

class RouteManagementDashboard extends StatefulWidget {
  final String? clientName;
  const RouteManagementDashboard({this.clientName, super.key});

  @override
  State<RouteManagementDashboard> createState() => _RouteManagementDashboardState();
}

class _RouteManagementDashboardState extends State<RouteManagementDashboard> {
  @override
  void initState() {
    super.initState();
    if (widget.clientName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AddTaskScreen(initialClientName: widget.clientName),
          ),
        );
      });
    }
  }

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
                        mainAxisExtent: crossAxisCount == 1 ? 160.sdp : 150.sdp,
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
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A2742).withAlpha(50),
                blurRadius: 24.sdp,
                offset: Offset(0, 8.sdp),
              ),
            ],
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
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A2742).withAlpha(50),
                blurRadius: 24.sdp,
                offset: Offset(0, 8.sdp),
              ),
            ],
          );

    final titleColor = isHighlighted ? Colors.white : colorScheme.onSurface;
    final bodyColor = isHighlighted
        ? Colors.white.withValues(alpha: 0.76)
        : colorScheme.onSurface.withValues(alpha: 0.64);
    final iconBgColor = isHighlighted
        ? option.accent.withValues(alpha: 0.12)
        : option.accent.withValues(alpha: 0.10);
    return GestureDetector(
      onTap: () {
        if (option.title == 'Track Field Executive') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const FieldExecutiveTrackingScreen(),
            ),
          );
          return;
        }

        if (option.title == 'View or Edit Visit Details') {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const VisitDetailsScreen()));
          return;
        }

        if (option.title == 'Add New Visit') {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddTaskScreen()));
          return;
        }

        if (option.title == 'View Today\'s Route Details') {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ViewRouteDetailsScreen()),
          );
          return;
        }

        SnackbarService.showComingSoon();
      },
      child: Container(
        decoration: backgroundDecoration,
        child: Padding(
          padding: EdgeInsets.all(20.sdp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 42.sdp,
                    height: 42.sdp,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(14.sdp),
                    ),
                    child: Icon(
                      option.icon,
                      color: option.accent,
                      size: 20.sdp,
                    ),
                  ),
                  SizedBox(width: 12.sdp),
                  Expanded(
                    child: Text(
                      option.title,
                      style: AppTextStyle.extraBold.custom(16.ssp, titleColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
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
    );
  }
}

class _RouteDashboardOption {
  final String title;
  final String description;
  final String? tag;
  final IconData icon;
  final Color accent;
  final bool isHighlighted;

  const _RouteDashboardOption({
    required this.title,
    required this.description,
    this.tag,
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
    icon: PhosphorIconsRegular.mapPinLine,
    accent: Color(0xFF38D39F),
    isHighlighted: true,
  ),
  _RouteDashboardOption(
    title: 'Add New Visit',
    description:
        'Add client visits, preferred timeslots and visit objectives in just a few taps.',
    icon: PhosphorIconsRegular.plusCircle,
    accent: Colors.green,
  ),
  _RouteDashboardOption(
    title: 'View or Edit Visit Details',
    description:
    'See a consolidated view of which executive owns which clients, upcoming visits and status.',
    icon: PhosphorIconsRegular.eye,
    accent: Colors.indigo,
  ),
  _RouteDashboardOption(
    title: 'View Today\'s Route Details',
    description:
        'View exact route details, distances, and ETAs for each client',
    icon: PhosphorIconsRegular.path,
    accent: Colors.orange,
  ),
];
