import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mnivesh_central/Models/announcement.dart';
import 'package:mnivesh_central/Themes/AppTextStyle.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../Utils/Dimensions.dart';
import '../../../ViewModels/announcement_viewModel.dart';
import '../../Screens/Daftar/AnnouncementModalScreen.dart';

// ─── Priority color coding (mirrors AnnouncementModalScreen) ────────────────
extension _BannerPriorityColor on AnnouncementPriority {
  Color get accent => switch (this) {
        AnnouncementPriority.critical => const Color(0xFFE05C6A),
        AnnouncementPriority.high => const Color(0xFFE8A045),
        AnnouncementPriority.normal => const Color(0xFF3B82F6),
      };

  List<Color> get darkGradient => switch (this) {
        AnnouncementPriority.critical => [
            const Color(0xFF2A1A1C),
            const Color(0xFF1F2130),
          ],
        AnnouncementPriority.high => [
            const Color(0xFF221C10),
            const Color(0xFF1F2130),
          ],
        AnnouncementPriority.normal => [
            const Color(0xFF1A202C),
            const Color(0xFF1F2130),
          ],
      };

  List<Color> get lightGradient => switch (this) {
        AnnouncementPriority.critical => [
            const Color(0xFFFFF5F6),
            const Color(0xFFFCFCFD),
          ],
        AnnouncementPriority.high => [
            const Color(0xFFFFF8EE),
            const Color(0xFFFCFCFD),
          ],
        AnnouncementPriority.normal => [
            const Color(0xFFF0F6FF),
            const Color(0xFFFCFCFD),
          ],
      };

  IconData get icon => switch (this) {
        AnnouncementPriority.critical =>
          PhosphorIcons.warning(PhosphorIconsStyle.fill),
        AnnouncementPriority.high =>
          PhosphorIcons.bellRinging(PhosphorIconsStyle.fill),
        AnnouncementPriority.normal =>
          PhosphorIcons.info(PhosphorIconsStyle.fill),
      };
}

// ─── Carousel Banner Section ────────────────────────────────────────────────
class AnnouncementsBanner extends ConsumerStatefulWidget {
  const AnnouncementsBanner({super.key});

  @override
  ConsumerState<AnnouncementsBanner> createState() =>
      _AnnouncementsBannerState();
}

class _AnnouncementsBannerState extends ConsumerState<AnnouncementsBanner> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll(int itemCount) {
    _autoScrollTimer?.cancel();
    if (itemCount <= 1) return;

    _autoScrollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        if (!_pageController.hasClients) return;
        final nextPage = (_currentPage + 1) % itemCount;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final announcementState = ref.watch(announcementViewModelProvider);
    final announcements = announcementState.items;
    final isLoading = announcementState.isLoading;

    if (isLoading && announcements.isEmpty) {
      return const _AnnouncementsSkeletonBanner();
    }

    if (announcements.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Start/restart auto-scroll whenever the list changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll(announcements.length);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(6.sdp, 20.sdp, 6.sdp, 5.sdp),
          child: Row(
            children: [
              Text(
                'NOTIFICATIONS',
                style: AppTextStyle.bold
                    .custom(16.ssp)
                    .copyWith(letterSpacing: 2.ssp),
              ),
              SizedBox(width: 10.sdp),
              Expanded(
                child: Container(
                  height: 1.sdp,
                  color: isDark
                      ? Colors.white.withAlpha(20)
                      : Colors.black.withAlpha(40),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.sdp),

        // ── PageView Carousel ───────────────────────────────────
        SizedBox(
          height: 106.sdp,
          child: PageView.builder(
            controller: _pageController,
            itemCount: announcements.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
              // Reset auto-scroll timer on manual swipe
              _startAutoScroll(announcements.length);
            },
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.sdp),
                child: _AnnouncementBannerCard(item: announcements[index]),
              );
            },
          ),
        ),

        // ── Dot Indicators ──────────────────────────────────────
        if (announcements.length > 1)
          Padding(
            padding: EdgeInsets.only(top: 10.sdp),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                announcements.length,
                (index) {
                  final isActive = index == _currentPage;
                  final dotColor = isActive
                      ? Colors.blue
                      : (isDark
                          ? Colors.white.withAlpha(40)
                          : Colors.black.withAlpha(35));

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.symmetric(horizontal: 3.sdp),
                    width: isActive ? 20.sdp : 6.sdp,
                    height: 6.sdp,
                    decoration: BoxDecoration(
                      color: dotColor,
                      borderRadius: BorderRadius.circular(3.sdp),
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Individual Banner Card ─────────────────────────────────────────────────
class _AnnouncementBannerCard extends StatelessWidget {
  const _AnnouncementBannerCard({required this.item});

  final Announcement item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = item.priority.accent;
    final gradient =
        isDark ? item.priority.darkGradient : item.priority.lightGradient;
    final colorScheme = Theme.of(context).colorScheme;
    final announcements =
        ProviderScope.containerOf(context)
            .read(announcementViewModelProvider)
            .items;

    return GestureDetector(
      onTap: () => AnnouncementModal.show(
        context,
        initialItems: announcements,
        expandId: item.id,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.sdp),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.18 : 0.22),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.05 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(14.sdp, 12.sdp, 14.sdp, 10.sdp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: icon + priority + author ────────────
              Row(
                children: [
                  Icon(item.priority.icon, size: 14.sdp, color: accent),
                  SizedBox(width: 6.sdp),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 7.sdp,
                      vertical: 2.sdp,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4.sdp),
                      border: Border.all(
                        color: accent.withValues(alpha: 0.28),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      item.priority.label,
                      style: AppTextStyle.bold.custom(9.ssp, accent),
                    ),
                  ),
                  if (item.isNew) ...[
                    SizedBox(width: 6.sdp),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.sdp,
                        vertical: 2.sdp,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4.sdp),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.28),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'NEW',
                        style: AppTextStyle.bold.custom(9.ssp, Colors.blue),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '${item.uploadedBy}  ·  ${_timeAgo(item.uploadedOn)}',
                    style: AppTextStyle.normal.custom(
                      10.5.ssp,
                      colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.sdp),

              // ── Message (1 line with ellipsis) ───────────────
              Text(
                item.title.trim().isNotEmpty ? item.title : item.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.normal.custom(
                  13.ssp,
                  colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 10.sdp),

              // ── Read more button ─────────────────────────────
              Align(
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  onTap: () => AnnouncementModal.show(
                    context,
                    initialItems: announcements,
                    expandId: item.id,
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(top: 2.sdp, bottom: 2.sdp),
                    child: Text(
                      'Read more >',
                      style: AppTextStyle.bold.custom(11.ssp, accent),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Relative time helper ───────────────────────────────────────────────────
String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
  return '${(diff.inDays / 30).floor()}mo ago';
}

// ─── Skeleton Loading Banner ────────────────────────────────────────────────
class _AnnouncementsSkeletonBanner extends StatelessWidget {
  const _AnnouncementsSkeletonBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(6.sdp, 20.sdp, 6.sdp, 5.sdp),
          child: Row(
            children: [
              Text(
                'NOTIFICATIONS',
                style: AppTextStyle.bold
                    .custom(16.ssp)
                    .copyWith(letterSpacing: 2.ssp),
              ),
              SizedBox(width: 10.sdp),
              Expanded(
                child: Container(
                  height: 1.sdp,
                  color: isDark
                      ? Colors.white.withAlpha(20)
                      : Colors.black.withAlpha(40),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.sdp),

        // ── Skeleton Card ───────────────────────────────────────
        SizedBox(
          height: 106.sdp,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.sdp),
            child: Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.white,
                  borderRadius: BorderRadius.circular(16.sdp),
                  border: Border.all(
                    color: isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(20),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14.sdp, 12.sdp, 14.sdp, 10.sdp),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: icon/priority placeholder + date placeholder
                      Row(
                        children: [
                          Container(
                            width: 60.sdp,
                            height: 16.sdp,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.sdp),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            width: 100.sdp,
                            height: 12.sdp,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.sdp),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.sdp),

                      // Message lines
                      Container(
                        width: double.infinity,
                        height: 14.sdp,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.sdp),
                        ),
                      ),
                      SizedBox(height: 6.sdp),
                      Container(
                        width: 200.sdp,
                        height: 14.sdp,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4.sdp),
                        ),
                      ),
                      const Spacer(),

                      // Read more placeholder
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          width: 60.sdp,
                          height: 12.sdp,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4.sdp),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
