import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../Themes/AppTextStyle.dart';
import '../../Utils/Dimensions.dart';
import '../../ViewModels/marketing_viewModel.dart';
import '../Widgets/Marketing/AsyncButtons.dart';
import '../Widgets/ModuleAppBar.dart';

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
                      return Center(
                        child: CircularProgressIndicator.adaptive(
                          valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                        ),
                      );
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
                              return _buildImageCard(section.imageUrls[imgIndex], colorScheme);
                            }, childCount: section.imageUrls.length),
                          ),
                        ),
                      );
                    }

                    slivers.add(SliverPadding(padding: EdgeInsets.only(bottom: 60.sdp)));

                    return CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: slivers,
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

  void _openExpandedImage(String imageUrl, ColorScheme colorScheme) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(20.sdp),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: PhosphorIcon(
                                PhosphorIcons.x(PhosphorIconsStyle.bold),
                                color: Colors.white,
                                size: 20.sdp,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InteractiveViewer(
                            clipBehavior: Clip.none,
                            child: Center(
                              child: Hero(
                                tag: imageUrl,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20.sdp),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 30.sdp,
                                        offset: Offset(0, 10.sdp),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20.sdp),
                                    child: CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) => Center(
                                        child: CircularProgressIndicator.adaptive(
                                          valueColor: AlwaysStoppedAnimation(
                                            Colors.white.withOpacity(0.8),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 16.sdp,
                          children: [
                            AsyncExpandedButton(
                              icon: PhosphorIcons.shareNetwork(PhosphorIconsStyle.bold),
                              label: 'Share',
                              colorScheme: colorScheme,
                              isPrimary: false,
                              onTap: () => _viewModel.shareImage(imageUrl),
                            ),
                            AsyncExpandedButton(
                              icon: PhosphorIcons.downloadSimple(PhosphorIconsStyle.bold),
                              label: 'Download',
                              colorScheme: colorScheme,
                              isPrimary: true,
                              onTap: () => _viewModel.downloadImage(imageUrl),
                            ),
                          ],
                        ),
                        SizedBox(height: 24.sdp),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageCard(String imageUrl, ColorScheme colorScheme) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _openExpandedImage(imageUrl, colorScheme),
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
              tag: imageUrl,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19.sdp),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Container(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    child: Center(
                      child: SizedBox(
                        width: 24.sdp,
                        height: 24.sdp,
                        child: const CircularProgressIndicator.adaptive(strokeWidth: 2.5),
                      ),
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
                    icon: PhosphorIcons.shareNetwork(PhosphorIconsStyle.fill),
                    colorScheme: colorScheme,
                    isFilled: false,
                    onTap: () => _viewModel.shareImage(imageUrl),
                  ),
                  AsyncCircleButton(
                    icon: PhosphorIcons.downloadSimple(PhosphorIconsStyle.bold),
                    colorScheme: colorScheme,
                    isFilled: true,
                    onTap: () => _viewModel.downloadImage(imageUrl),
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