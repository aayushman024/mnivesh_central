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

    // Default to Store tab on iOS since local installs aren't tracked
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: Platform.isIOS ? 2 : 0,
    );

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
    if (state == AppLifecycleState.resumed) {
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
    if (!Platform.isAndroid) {
      if (mounted) {
        setState(() {
          _installedStatus.clear();
          _updateStatus.clear();
          for (var app in apps) {
            _installedStatus[app.packageName] = false;
            _updateStatus[app.packageName] = false;
          }
          _isStatusChecking = false;
        });
      }
      return;
    }

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
        case 0: return isInstalled;
        case 1: return isInstalled && isUpdate;
        case 2: return !isInstalled;
        default: return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color activeBlue = isDark ? const Color(0xFF93C5FD) : const Color(0xFF2563EB);
    final Color bgColor = Theme.of(context).scaffoldBackgroundColor;

    final appsAsyncValue = ref.watch(appsProvider);

    return Container(
      color: bgColor,
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isStatusChecking = true);
          final newApps = await ref.refresh(appsProvider.future);
          await _checkAppsStatus(newApps);
        },
        color: Colors.white,
        backgroundColor: activeBlue,
        child: NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            const HomeSliverAppBar(),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  indicator: BoxDecoration(
                    color: activeBlue.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: activeBlue.withOpacity(isDark ? 0.3 : 0.2),
                      width: 1,
                    ),
                  ),
                  labelColor: activeBlue,
                  unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  tabs: const [
                    Tab(text: "Installed"),
                    Tab(text: "Updates"),
                    Tab(text: "Store"),
                  ],
                ),
                bgColor,
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
            error: (err, stack) => Center(child: Text("Error: $err")),
            loading: () => const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(List<AppModel> filteredApps, int tabIndex) {
    if (filteredApps.isEmpty) {
      return Center(child: Text(_getEmptyMessage(tabIndex), style: const TextStyle(color: Colors.grey)));
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
      default: return "";
    }
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color _bgColor;

  _SliverAppBarDelegate(this._tabBar, this._bgColor);

  @override
  double get minExtent => _tabBar.preferredSize.height + 16;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 16;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: _bgColor, child: Center(child: _tabBar));
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}