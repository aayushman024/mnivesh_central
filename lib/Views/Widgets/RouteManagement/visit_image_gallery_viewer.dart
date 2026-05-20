import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';
import '../../../Utils/route_visit_image_util.dart';

class VisitImageGalleryViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String title;

  const VisitImageGalleryViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    required this.title,
  });

  @override
  State<VisitImageGalleryViewer> createState() => _VisitImageGalleryViewerState();
}

class _VisitImageGalleryViewerState extends State<VisitImageGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isDownloadingAll = false;
  bool _isSharingAll = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Zoomable Image PageView
          GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! > 600) {
                Navigator.of(context).pop();
              }
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final url = widget.imageUrls[index];
                return Center(
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: Colors.white.withValues(alpha: 0.08),
                          highlightColor: Colors.white.withValues(alpha: 0.16),
                          child: Container(
                            color: Colors.black,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorIcons.warningCircle(),
                              color: Colors.redAccent,
                              size: 40.sdp,
                            ),
                            SizedBox(height: 12.sdp),
                            Text(
                              'Failed to load image',
                              style: AppTextStyle.bold.custom(14.ssp, Colors.white70),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          // 2. Top Glassmorphic Navigation Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 10.sdp,
                bottom: 12.sdp,
                left: 16.sdp,
                right: 16.sdp,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black87, Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      PhosphorIcons.x(),
                      color: Colors.white,
                      size: 24.sdp,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Text(
                    '${_currentIndex + 1} of ${widget.imageUrls.length}',
                    style: AppTextStyle.bold.custom(16.ssp, Colors.white),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          PhosphorIcons.download(),
                          color: Colors.white,
                          size: 22.sdp,
                        ),
                        onPressed: () => RouteVisitImageUtil.downloadUrlToGallery(
                          widget.imageUrls[_currentIndex],
                          '${widget.title}_${_currentIndex + 1}',
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          PhosphorIcons.share(),
                          color: Colors.white,
                          size: 22.sdp,
                        ),
                        onPressed: () => RouteVisitImageUtil.shareUrl(
                          widget.imageUrls[_currentIndex],
                          text: 'Image from ${widget.title}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Glassmorphic Actions Panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: 20.sdp,
                bottom: MediaQuery.of(context).padding.bottom + 20.sdp,
                left: 20.sdp,
                right: 20.sdp,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48.sdp,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24.sdp),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: ElevatedButton.icon(
                        icon: _isSharingAll
                            ? SizedBox(
                                width: 18.sdp,
                                height: 18.sdp,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                PhosphorIcons.shareNetwork(),
                                size: 20.sdp,
                                color: Colors.white,
                              ),
                        label: Text(
                          'Share All (${widget.imageUrls.length})',
                          style: AppTextStyle.bold.custom(13.ssp, Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.sdp),
                          ),
                        ),
                        onPressed: _isSharingAll
                            ? null
                            : () async {
                                setState(() => _isSharingAll = true);
                                await RouteVisitImageUtil.shareAllUrls(
                                  widget.imageUrls,
                                  text: 'Completion images for ${widget.title}',
                                );
                                if (mounted) setState(() => _isSharingAll = false);
                              },
                      ),
                    ),
                  ),
                  SizedBox(width: 12.sdp),
                  Expanded(
                    child: Container(
                      height: 48.sdp,
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(24.sdp),
                        border: Border.all(
                          color: Colors.white24,
                          width: 1,
                        ),
                      ),
                      child: ElevatedButton.icon(
                        icon: _isDownloadingAll
                            ? SizedBox(
                                width: 18.sdp,
                                height: 18.sdp,
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                PhosphorIcons.downloadSimple(),
                                size: 20.sdp,
                                color: Colors.white,
                              ),
                        label: Text(
                          'Download All (${widget.imageUrls.length})',
                          style: AppTextStyle.bold.custom(13.ssp, Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.sdp),
                          ),
                        ),
                        onPressed: _isDownloadingAll
                            ? null
                            : () async {
                                setState(() => _isDownloadingAll = true);
                                await RouteVisitImageUtil.downloadAllToGallery(
                                  widget.imageUrls,
                                  widget.title,
                                );
                                if (mounted) setState(() => _isDownloadingAll = false);
                              },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
