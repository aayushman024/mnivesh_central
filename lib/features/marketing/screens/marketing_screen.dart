import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mnivesh_central/features/marketing/models/marketing_model.dart';
import 'package:mnivesh_central/core/theme/app_text_style.dart';
import 'package:mnivesh_central/core/utils/dimensions.dart';
import 'package:mnivesh_central/features/marketing/view_models/marketing_view_model.dart';
import 'package:mnivesh_central/features/marketing/widgets/async_buttons.dart';
import 'package:mnivesh_central/features/route_management/widgets/module_app_bar.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  late final MarketingViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MarketingViewModel();
    _viewModel.loadData();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // using sizeOf to prevent keyboard pop rebuilds
    final screenWidth = MediaQuery.sizeOf(context).width;
    final crossAxisCount = screenWidth > 600 ? 4 : 2;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModuleAppBar(title: "Marketing Templates"),
      body: Column(
        children: [
          SizedBox(height: 8.sdp),
          ListenableBuilder(
            listenable: _viewModel,
            builder: (context, _) {
              if (_viewModel.categories.isEmpty) return const SizedBox.shrink();
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 20.sdp, vertical: 8.sdp),
                child: Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 8.sdp),
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: _viewModel.selectedCategoryKey == null,
                        onSelected: (selected) {
                          if (selected) _viewModel.onCategorySelected(null);
                        },
                      ),
                    ),
                    ..._viewModel.categories.map((category) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8.sdp),
                        child: ChoiceChip(
                          label: Text(category.label),
                          selected: _viewModel.selectedCategoryKey == category.key,
                          onSelected: (selected) {
                            if (selected) _viewModel.onCategorySelected(category.key);
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 8.sdp),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.sdp)),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 24.sdp,
                    offset: Offset(0, -4.sdp),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(32.sdp)),
                child: ListenableBuilder(
                  listenable: _viewModel,
                  builder: (context, child) {
                    if (_viewModel.isLoading) {
                      return _buildSkeletonLoader(colorScheme, crossAxisCount);
                    }

                    if (_viewModel.sections.isEmpty) {
                      return _buildEmptyState(colorScheme);
                    }

                    final slivers = <Widget>[];

                    for (var i = 0; i < _viewModel.sections.length; i++) {
                      final section = _viewModel.sections[i];

                      // section header with modern vertical accent
                      slivers.add(
                        SliverPadding(
                          padding: EdgeInsets.only(
                            left: 20.sdp,
                            right: 20.sdp,
                            bottom: 20.sdp,
                            top: i == 0 ? 32.sdp : 40.sdp,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.sdp, vertical: 8.sdp),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withAlpha(70),
                                  borderRadius: BorderRadius.circular(15.sdp),
                                  border: Border.all(color: colorScheme.primary),
                                ),
                                child: Text(
                                  section.title,
                                  style: AppTextStyle.extraBold
                                      .normal(colorScheme.onSurface)
                                      .copyWith(fontSize: 18.ssp, letterSpacing: 0.2),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );

                      // image grid
                      slivers.add(
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 20.sdp),
                          sliver: SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 20.sdp,
                              mainAxisSpacing: 36.sdp,
                              childAspectRatio: 0.75,
                            ),
                            delegate: SliverChildBuilderDelegate((context, imgIndex) {
                              return _buildImageCard(section.templates[imgIndex], colorScheme);
                            }, childCount: section.templates.length),
                          ),
                        ),
                      );
                    }

                    return RefreshIndicator.adaptive(
                      onRefresh: _viewModel.loadData,
                      color: colorScheme.primary,
                      backgroundColor: theme.cardColor,
                      child: CustomScrollView(
                        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        slivers: slivers,
                      ),
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

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return RefreshIndicator.adaptive(
      onRefresh: _viewModel.loadData,
      color: colorScheme.primary,
      backgroundColor: Theme.of(context).cardColor,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: EdgeInsets.all(40.sdp),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(24.sdp),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      PhosphorIconsRegular.fileX,
                      size: 64.sdp,
                      color: colorScheme.onSurface.withOpacity(0.2),
                    ),
                  ),
                  SizedBox(height: 24.sdp),
                  Text(
                    'No Templates Found',
                    textAlign: TextAlign.center,
                    style: AppTextStyle.extraBold.custom(20.ssp, colorScheme.onSurface),
                  ),
                  SizedBox(height: 12.sdp),
                  Text(
                    'We couldn\'t find any marketing templates in this category. Try selecting another one or check back later.',
                    textAlign: TextAlign.center,
                    style: AppTextStyle.normal.custom(14.ssp, colorScheme.onSurface.withOpacity(0.5)),
                  ),
                  SizedBox(height: 32.sdp),
                  FilledButton.tonal(
                    onPressed: () => _viewModel.onCategorySelected(null),
                    child: const Text('View All Templates'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // match the skeleton layout with the real list layout
  Widget _buildSkeletonLoader(ColorScheme colorScheme, int crossAxisCount) {
    return Shimmer.fromColors(
      baseColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
      highlightColor: colorScheme.surface,
      child: CustomScrollView(
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          _buildSkeletonSection(crossAxisCount, isFirst: true),
          _buildSkeletonSection(crossAxisCount, isFirst: false),
        ],
      ),
    );
  }

  Widget _buildSkeletonSection(int crossAxisCount, {required bool isFirst}) {
    return SliverMainAxisGroup(
      slivers: [
        // skeleton header
        SliverPadding(
          padding: EdgeInsets.only(
            left: 20.sdp,
            right: 20.sdp,
            bottom: 20.sdp,
            top: isFirst ? 32.sdp : 40.sdp,
          ),
          sliver: SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                height: 38.sdp, // approx height of the real header
                width: 140.sdp,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.sdp),
                ),
              ),
            ),
          ),
        ),
        // skeleton grid items
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20.sdp),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20.sdp,
              mainAxisSpacing: 36.sdp,
              childAspectRatio: 0.75,
            ),
            // render a couple of rows of dummy cards
            delegate: SliverChildBuilderDelegate((context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.sdp),
                ),
              );
            }, childCount: crossAxisCount * 2),
          ),
        ),
      ],
    );
  }


  void _openExpandedImage(MarketingTemplate template, ColorScheme colorScheme) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ExpandedImagePage(
            template: template,
            colorScheme: colorScheme,
            viewModel: _viewModel,
          );
        },
      ),
    );
  }

  Widget _buildImageCard(MarketingTemplate template, ColorScheme colorScheme) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _openExpandedImage(template, colorScheme),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.sdp),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withOpacity(0.04),
                  blurRadius: 12.sdp,
                  offset: Offset(0, 4.sdp),
                ),
              ],
            ),
            child: Hero(
              tag: template.id,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19.sdp),
                child: CachedNetworkImage(
                  imageUrl: template.proxyImageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  memCacheWidth: 300, // Optimized for grid thumbnail
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    highlightColor: colorScheme.surface,
                    child: Container(
                      color: Colors.white,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -18.sdp,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.sdp, vertical: 6.sdp),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(30.sdp),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.08),
                    blurRadius: 16.sdp,
                    offset: Offset(0, 6.sdp),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8.sdp,
                children: [
                  AsyncCircleButton(
                    icon: PhosphorIconsFill.shareNetwork,
                    colorScheme: colorScheme,
                    isFilled: false,
                    onTap: () => _viewModel.shareImage(template),
                  ),
                  AsyncCircleButton(
                    icon: PhosphorIconsBold.downloadSimple,
                    colorScheme: colorScheme,
                    isFilled: true,
                    onTap: () => _viewModel.downloadImage(template),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Expanded image overlay — owns all gesture + animation state
// ---------------------------------------------------------------------------
class _ExpandedImagePage extends StatefulWidget {
  final MarketingTemplate template;
  final ColorScheme colorScheme;
  final MarketingViewModel viewModel;

  const _ExpandedImagePage({
    required this.template,
    required this.colorScheme,
    required this.viewModel,
  });

  @override
  State<_ExpandedImagePage> createState() => _ExpandedImagePageState();
}

class _ExpandedImagePageState extends State<_ExpandedImagePage>
    with TickerProviderStateMixin {
  // ── Controllers ─────────────────────────────────────────────────────────
  late final TransformationController _transformController;
  late final AnimationController _dismissController;
  late final AnimationController _zoomResetController;

  // current animated value for the snap/dismiss animation
  late Animation<double> _offsetAnimation;

  // Key used to read the InteractiveViewer's rendered size for focal-point math.
  final GlobalKey _viewerKey = GlobalKey();

  // ── Drag state ───────────────────────────────────────────────────────────
  double _dragOffset = 0.0;

  // ── Thresholds ───────────────────────────────────────────────────────────
  static const double _kOffsetThreshold  = 180.0; // px
  static const double _kVelocityThreshold = 600.0; // px/s

  // ── Helpers ──────────────────────────────────────────────────────────────
  /// True when the InteractiveViewer is at its original 1× scale.
  bool get _isAtIdentityScale {
    final m = _transformController.value;
    // entry(0,0) is the X-scale of the matrix.
    return m.entry(0, 0) <= 1.001;
  }

  double _calcDragProgress(double screenH) {
    // Normalise against 45% of screen height so the effect kicks in early.
    return (_dragOffset / (screenH * 0.45)).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();

    _transformController = TransformationController()
      ..addListener(_onTransformChanged);

    _dismissController = AnimationController(vsync: this);
    _zoomResetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    // Initialise to a stopped animation so the field is never late-unset.
    _offsetAnimation = const AlwaysStoppedAnimation(0.0);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    _dismissController.dispose();
    _zoomResetController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    // Rebuild so panEnabled on InteractiveViewer flips correctly.
    if (mounted) setState(() {});
  }

  // ── Drag handlers ────────────────────────────────────────────────────────
  void _onDragStart(DragStartDetails _) {
    if (!_isAtIdentityScale) return;
    _dismissController.stop();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isAtIdentityScale) return;
    final next = _dragOffset + details.delta.dy;
    if (next < 0) return; // no upward drag
    setState(() => _dragOffset = next);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_isAtIdentityScale) return;
    final vy = details.velocity.pixelsPerSecond.dy;
    final shouldDismiss =
        _dragOffset > _kOffsetThreshold || vy > _kVelocityThreshold;
    shouldDismiss ? _runDismissExit() : _runSnapBack();
  }

  // ── Animation helpers ────────────────────────────────────────────────────
  void _onOffsetTick() {
    if (mounted) setState(() => _dragOffset = _offsetAnimation.value);
  }

  void _runSnapBack() {
    _dismissController.duration = const Duration(milliseconds: 420);
    _offsetAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _dismissController, curve: Curves.easeOutBack),
    );
    _offsetAnimation.addListener(_onOffsetTick);
    _dismissController.forward(from: 0).then(
      (_) => _offsetAnimation.removeListener(_onOffsetTick),
    );
  }

  void _runDismissExit() {
    final screenH = MediaQuery.of(context).size.height;
    _dismissController.duration = const Duration(milliseconds: 250);
    _offsetAnimation =
        Tween<double>(begin: _dragOffset, end: screenH).animate(
      CurvedAnimation(parent: _dismissController, curve: Curves.easeIn),
    );
    _offsetAnimation.addListener(_onOffsetTick);
    _dismissController.forward(from: 0).then((_) {
      _offsetAnimation.removeListener(_onOffsetTick);
      if (mounted) Navigator.of(context).pop();
    });
  }

  // ── Double-tap: toggle 1× ↔ 2× (zoom anchored to viewport centre) ────────
  void _onDoubleTap() {
    _zoomResetController.stop();
    final begin = _transformController.value.clone();

    Matrix4 end;
    if (_isAtIdentityScale) {
      // Compute the centre of the InteractiveViewer's viewport.
      final box = _viewerKey.currentContext?.findRenderObject() as RenderBox?;
      final size = box?.size ?? MediaQuery.sizeOf(context);
      final cx = size.width / 2;
      final cy = size.height / 2;
      // Scale about (cx, cy): T(cx,cy) * S(2) * T(-cx,-cy)
      end = Matrix4.identity()
        ..translate(cx, cy)
        ..scale(2.0)
        ..translate(-cx, -cy);
    } else {
      end = Matrix4.identity();
    }

    final anim = Matrix4Tween(begin: begin, end: end).animate(
      CurvedAnimation(parent: _zoomResetController, curve: Curves.easeOutCubic),
    );
    void listener() => _transformController.value = anim.value;
    anim.addListener(listener);
    _zoomResetController
        .forward(from: 0)
        .then((_) => anim.removeListener(listener));
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final screenH   = MediaQuery.sizeOf(context).height;
    final progress = _calcDragProgress(screenH);
    final backdropOpacity = 0.6 * (1.0 - progress);
    final blurSigma      = 12.0 * (1.0 - progress);
    final imageScale     = 1.0 - progress * 0.25;
    final uiOpacity      = (1.0 - progress * 2.5).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onVerticalDragStart: _onDragStart,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        // Backdrop tap still dismisses
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Animated backdrop ────────────────────────────────────────
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: Container(
                color: Colors.black.withOpacity(backdropOpacity),
              ),
            ),

            // ── Draggable content layer ──────────────────────────────────
            Transform.translate(
              offset: Offset(0, _dragOffset),
              child: Transform.scale(
                scale: imageScale,
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(20.sdp),
                    child: Column(
                      children: [
                        // Close button — fades out as you drag
                        Opacity(
                          opacity: uiOpacity,
                          child: Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15.sdp),
                              ),
                              child: TextButton.icon(
                                label: Text(
                                  'Close',
                                  style: AppTextStyle.normal
                                      .normal(widget.colorScheme.surface),
                                ),
                                onPressed: () => Navigator.of(context).pop(),
                                icon: Icon(
                                  PhosphorIconsBold.x,
                                  color: Colors.white,
                                  size: 20.sdp,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Image
                        Expanded(
                          child: GestureDetector(
                            // Absorb taps inside the image so they don't
                            // bubble to the backdrop-dismiss handler above.
                            onTap: () {},
                            onDoubleTap: _onDoubleTap,
                            child: InteractiveViewer(
                              key: _viewerKey,
                              transformationController: _transformController,
                              clipBehavior: Clip.none,
                              minScale: 1.0,
                              maxScale: 4.0,
                              // Disable pan at 1× so the outer vertical-drag
                              // GestureDetector wins the gesture arena.
                              panEnabled: !_isAtIdentityScale,
                              child: Center(
                                child: Hero(
                                  tag: widget.template.id,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius:
                                          BorderRadius.circular(20.sdp),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              Colors.black.withOpacity(0.3),
                                          blurRadius: 30.sdp,
                                          offset: Offset(0, 10.sdp),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(20.sdp),
                                      child: CachedNetworkImage(
                                        imageUrl:
                                            widget.template.proxyImageUrl,
                                        fit: BoxFit.contain,
                                        memCacheWidth: 800,
                                        placeholder: (context, url) =>
                                            Shimmer.fromColors(
                                          baseColor: widget.colorScheme
                                              .onSurface
                                              .withOpacity(0.1),
                                          highlightColor: widget.colorScheme
                                              .onSurface
                                              .withOpacity(0.05),
                                          child: Container(
                                            color: Colors.white,
                                            width: double.infinity,
                                            height: double.infinity,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 32.sdp),

                        // Action buttons — fade out while dragging
                        Opacity(
                          opacity: uiOpacity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AsyncExpandedButton(
                                icon: PhosphorIconsBold.shareNetwork,
                                label: 'Share',
                                colorScheme: widget.colorScheme,
                                isPrimary: false,
                                onTap: () =>
                                    widget.viewModel.shareImage(widget.template),
                              ),
                              SizedBox(width: 16.sdp),
                              AsyncExpandedButton(
                                icon: PhosphorIconsBold.downloadSimple,
                                label: 'Download',
                                colorScheme: widget.colorScheme,
                                isPrimary: true,
                                onTap: () => widget.viewModel
                                    .downloadImage(widget.template),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 24.sdp),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
