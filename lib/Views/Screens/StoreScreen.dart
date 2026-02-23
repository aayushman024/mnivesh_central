import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:app_links/app_links.dart';

import '../../Models/appModel.dart';
import '../../Providers/app_provider.dart';
import '../../Services/permission_helper.dart';
import '../../ViewModels/app_card_view_model.dart';
import '../Widgets/homeAppBar.dart';

class StoreScreen extends ConsumerStatefulWidget {
  const StoreScreen({super.key});

  @override
  ConsumerState<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends ConsumerState<StoreScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  final Map<String, bool> _installedStatus = {};
  final Map<String, bool> _updateStatus = {};
  bool _isStatusChecking = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 3, vsync: this);

    if (Platform.isAndroid) {
      _askPermissions();
      _initDeepLinks();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _linkSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      final appsValue = ref.read(appsProvider);
      if (appsValue.hasValue) {
        _checkAppsStatus(appsValue.value!);
      }
    }
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    final tab = uri.queryParameters['tab'];
    if (tab == 'installed') {
      _tabController.animateTo(0);
    } else if (tab == 'updates') {
      _tabController.animateTo(1);
    } else if (tab == 'store') {
      _tabController.animateTo(2);
    }
  }

  Future<void> _askPermissions() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await PermissionHelper.requestAll();
  }

  Future<void> _checkAppsStatus(List<AppModel> apps) async {
    if (!Platform.isAndroid) return;

    Map<String, bool> newInstalled = {};
    Map<String, bool> newUpdates = {};

    for (var app in apps) {
      bool installed = await InstalledApps.isAppInstalled(app.packageName) ?? false;
      bool updateNeeded = false;

      if (installed) {
        AppInfo? info = await InstalledApps.getAppInfo(app.packageName);
        if (info != null && info.versionName != app.version) {
          updateNeeded = true;
        }
      }

      newInstalled[app.packageName] = installed;
      newUpdates[app.packageName] = updateNeeded;
    }

    if (mounted) {
      setState(() {
        _installedStatus.clear();
        _updateStatus.clear();
        _installedStatus.addAll(newInstalled);
        _updateStatus.addAll(newUpdates);
        _isStatusChecking = false;
      });
    }
  }

  List<AppModel> _getFilteredApps(List<AppModel> allApps, int tabIndex) {
    if (_isStatusChecking) return [];

    return allApps.where((app) {
      final isInstalled = _installedStatus[app.packageName] ?? false;
      final isUpdate = _updateStatus[app.packageName] ?? false;

      switch (tabIndex) {
        case 0: // Installed
          return isInstalled;
        case 1: // Updates
          return isInstalled && isUpdate;
        case 2: // Store
          return !isInstalled;
        default:
          return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) {
      return const CustomScrollView(
        slivers: [
          HomeSliverAppBar(userName: "Aayushman Ranjan"),
          SliverFillRemaining(
            child: Center(
              child: Text(
                "Store is only available on Android devices.",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          )
        ],
      );
    }

    final appsAsyncValue = ref.watch(appsProvider);

    ref.listen<AsyncValue<List<AppModel>>>(appsProvider, (prev, next) {
      next.whenData((apps) {
        if (_installedStatus.isEmpty || _installedStatus.length != apps.length) {
          _checkAppsStatus(apps);
        }
      });
    });

    // Removed Scaffold wrapper from here
    return Container(
      color: const Color(0xFF121218),
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isStatusChecking = true);
          final newApps = await ref.refresh(appsProvider.future);
          await _checkAppsStatus(newApps);
        },
        color: Colors.white,
        backgroundColor: const Color(0xFF7C4DFF),
        child: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            // Common App Bar
            const HomeSliverAppBar(userName: "Aayushman Ranjan"),
            // Sticky TabBar below the sliver app bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF7C4DFF),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  tabs: const [
                    Tab(text: "Installed"),
                    Tab(text: "Updates"),
                    Tab(text: "Store"),
                  ],
                ),
              ),
            ),
          ],
          body: appsAsyncValue.when(
            data: (apps) {
              if (_isStatusChecking && _installedStatus.isEmpty) {
                _checkAppsStatus(apps);
                return const Center(child: CircularProgressIndicator());
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildTabContent(_getFilteredApps(apps, 0), 0),
                  _buildTabContent(_getFilteredApps(apps, 1), 1),
                  _buildTabContent(_getFilteredApps(apps, 2), 2),
                ],
              );
            },
            error: (err, stack) => Center(child: Text("Error: $err", style: const TextStyle(color: Colors.red))),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(List<AppModel> filteredApps, int tabIndex) {
    if (filteredApps.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _getEmptyIconColor(tabIndex).withOpacity(0.2),
                      _getEmptyIconColor(tabIndex).withOpacity(0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.3, 0.6, 1.0],
                  ),
                ),
                child: Icon(
                  _getEmptyIcon(tabIndex),
                  size: 80,
                  color: _getEmptyIconColor(tabIndex),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _getEmptyMessage(tabIndex),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getEmptySubtitle(tabIndex),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      itemCount: filteredApps.length,
      itemBuilder: (context, index) => AppInfoCardContainer(
        key: ValueKey(filteredApps[index].packageName),
        app: filteredApps[index],
      ),
    );
  }

  String _getEmptyMessage(int index) {
    switch (index) {
      case 0: return "No apps installed yet";
      case 1: return "Everything's up to date";
      case 2: return "No apps in store";
      default: return "No apps found";
    }
  }

  String _getEmptySubtitle(int index) {
    switch (index) {
      case 0: return "Install apps from the store to get started";
      case 1: return "All your apps are running the latest versions";
      case 2: return "Check back later for new apps";
      default: return "";
    }
  }

  IconData _getEmptyIcon(int index) {
    switch (index) {
      case 0: return Icons.inventory_2_outlined;
      case 1: return Icons.verified_outlined;
      case 2: return Icons.store_outlined;
      default: return Icons.error_outline;
    }
  }

  Color _getEmptyIconColor(int index) {
    switch (index) {
      case 0: return const Color(0xFF7C4DFF).withOpacity(0.6);
      case 1: return const Color(0xFF4CAF50).withOpacity(0.6);
      case 2: return const Color(0xFF2196F3).withOpacity(0.6);
      default: return Colors.grey;
    }
  }
}

// sticky header behavior for TabBar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFF121218), // Match scaffold background
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}