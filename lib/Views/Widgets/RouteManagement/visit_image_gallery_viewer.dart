import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../../../Services/snackBar_Service.dart';
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
  State<VisitImageGalleryViewer> createState() =>
      _VisitImageGalleryViewerState();
}

class _VisitImageGalleryViewerState extends State<VisitImageGalleryViewer> {
  late PageController _pageController;
  late int _currentIndex;
  bool _isDownloadingAll = false;
  bool _isSharingAll = false;

  String _imageNameFor(int index) {
    final imageUrl = widget.imageUrls[index];
    final uri = Uri.tryParse(imageUrl);
    final rawName = uri?.pathSegments.isNotEmpty == true
        ? uri!.pathSegments.last
        : '';
    final decodedName = Uri.decodeComponent(rawName).trim();
    return decodedName.isNotEmpty ? decodedName : 'Image ${index + 1}';
  }

  String _downloadTitleFor(int index) {
    final imageName = _imageNameFor(index);
    final dotIndex = imageName.lastIndexOf('.');
    final baseName = dotIndex > 0
        ? imageName.substring(0, dotIndex)
        : imageName;
    final cleanName = baseName.trim().isNotEmpty
        ? baseName.trim()
        : widget.title;
    return '${cleanName}_${index + 1}';
  }

  Future<void> _downloadSelectedImages(List<int> selectedIndexes) async {
    if (selectedIndexes.isEmpty) {
      SnackbarService.showError(
        'Please select at least one image to download.',
      );
      return;
    }

    setState(() => _isDownloadingAll = true);

    try {
      await Future.wait(
        selectedIndexes.map(
          (index) => RouteVisitImageUtil.downloadUrlToGallery(
            widget.imageUrls[index],
            _downloadTitleFor(index),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloadingAll = false);
      }
    }
  }

  Future<void> _showDownloadSelectionSheet() async {
    final selections = List<bool>.filled(widget.imageUrls.length, true);

    final selectedIndexes = await showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final sheetTheme = Theme.of(sheetContext);

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedCount = selections
                .where((isSelected) => isSelected)
                .length;
            final isAllSelected = selectedCount == selections.length;
            final isNoneSelected = selectedCount == 0;

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 12.sdp,
                  right: 12.sdp,
                  bottom:
                      MediaQuery.of(sheetContext).viewInsets.bottom + 12.sdp,
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(sheetContext).size.height * 0.78,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171717),
                    borderRadius: BorderRadius.circular(24.sdp),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          20.sdp,
                          18.sdp,
                          12.sdp,
                          8.sdp,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Download Images',
                                    style: AppTextStyle.bold.custom(
                                      16.ssp,
                                      Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 4.sdp),
                                  Text(
                                    '$selectedCount of ${widget.imageUrls.length} selected',
                                    style: AppTextStyle.normal.custom(
                                      12.ssp,
                                      Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              icon: Icon(
                                PhosphorIconsRegular.x,
                                color: Colors.white70,
                                size: 20.sdp,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.sdp,
                            vertical: 8.sdp,
                          ),
                          itemCount: widget.imageUrls.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          itemBuilder: (context, index) {
                            return CheckboxListTile(
                              value: selections[index],
                              onChanged: (value) {
                                setSheetState(() {
                                  selections[index] = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.trailing,
                              activeColor: sheetTheme.colorScheme.primary,
                              checkColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.sdp,
                              ),
                              title: Text(
                                _imageNameFor(index),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyle.normal.custom(
                                  13.ssp,
                                  Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16.sdp,
                          12.sdp,
                          16.sdp,
                          16.sdp,
                        ),
                        child: Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setSheetState(() {
                                  final shouldSelectAll = isNoneSelected;
                                  for (int i = 0; i < selections.length; i++) {
                                    selections[i] = shouldSelectAll;
                                  }
                                });
                              },
                              child: Text(
                                isNoneSelected ? 'Select All' : 'Clear All',
                                style: AppTextStyle.bold.custom(
                                  13.ssp,
                                  isNoneSelected
                                      ? sheetTheme.colorScheme.primary
                                      : Colors.white70,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.sdp),
                            Expanded(
                              child: SizedBox(
                                height: 46.sdp,
                                child: ElevatedButton(
                                  onPressed: isNoneSelected
                                      ? null
                                      : () {
                                          Navigator.of(sheetContext).pop([
                                            for (
                                              int i = 0;
                                              i < selections.length;
                                              i++
                                            )
                                              if (selections[i]) i,
                                          ]);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        sheetTheme.colorScheme.primary,
                                    disabledBackgroundColor: Colors.white12,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        18.sdp,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    isAllSelected
                                        ? 'Download All'
                                        : 'Download Selected ($selectedCount)',
                                    style: AppTextStyle.bold.custom(
                                      13.ssp,
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || selectedIndexes == null) return;
    await _downloadSelectedImages(selectedIndexes);
  }

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
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! > 600) {
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
                              PhosphorIconsRegular.warningCircle,
                              color: Colors.redAccent,
                              size: 40.sdp,
                            ),
                            SizedBox(height: 12.sdp),
                            Text(
                              'Failed to load image',
                              style: AppTextStyle.bold.custom(
                                14.ssp,
                                Colors.white70,
                              ),
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
                      PhosphorIconsRegular.x,
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
                          PhosphorIconsRegular.download,
                          color: Colors.white,
                          size: 22.sdp,
                        ),
                        onPressed: () =>
                            RouteVisitImageUtil.downloadUrlToGallery(
                              widget.imageUrls[_currentIndex],
                              '${widget.title}_${_currentIndex + 1}',
                            ),
                      ),
                      IconButton(
                        icon: Icon(
                          PhosphorIconsRegular.share,
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
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
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
                                PhosphorIconsRegular.shareNetwork,
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
                                if (mounted) {
                                  setState(() => _isSharingAll = false);
                                }
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
                        border: Border.all(color: Colors.white24, width: 1),
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
                                PhosphorIconsRegular.downloadSimple,
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
                            : _showDownloadSelectionSheet,
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
