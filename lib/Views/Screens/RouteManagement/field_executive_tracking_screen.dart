import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../Utils/Dimensions.dart';
import '../../../ViewModels/routeOptimization_viewModel.dart';
import '../../Widgets/ModuleAppBar.dart';

class FieldExecutiveTrackingScreen extends StatefulWidget {
  const FieldExecutiveTrackingScreen({super.key});

  @override
  State<FieldExecutiveTrackingScreen> createState() =>
      _FieldExecutiveTrackingScreenState();
}

class _FieldExecutiveTrackingScreenState
    extends State<FieldExecutiveTrackingScreen> {
  late final RouteOptimizationViewModel _viewModel;
  GoogleMapController? _mapController;
  final Map<String, BitmapDescriptor> _markerIcons = {};
  bool _isMapReady = false;
  bool _iconsPrepared = false;

  @override
  void initState() {
    super.initState();
    _viewModel = RouteOptimizationViewModel();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_iconsPrepared) {
      _iconsPrepared = true;
      _prepareMarkerIcons(Theme.of(context).colorScheme.primary);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModuleAppBar(title: 'Route Management', isBackIcon: true),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, child) {
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _toGoogleLatLng(_viewModel.getInitialCenter()),
                  zoom: _viewModel.getInitialZoom(),
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _isMapReady = true;
                  _syncMapToSelection();
                },
                markers: _buildMarkers(theme),
                mapType: MapType.normal,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                trafficEnabled: false,
                indoorViewEnabled: false,
                buildingsEnabled: false,
                fortyFiveDegreeImageryEnabled: false,
                zoomControlsEnabled: true,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: true,
                liteModeEnabled: false,
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                minMaxZoomPreference: const MinMaxZoomPreference(4, 17),
                padding: EdgeInsets.only(top: 88.sdp),
                onTap: (_) => _viewModel.clearActiveExecutive(),
              ),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.sdp, 12.sdp, 16.sdp, 0),
                  child: _buildExecutiveDropdown(theme),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Set<Marker> _buildMarkers(ThemeData theme) {
    return _viewModel.visibleExecutives.map((executive) {
      final isActive = _viewModel.isMarkerActive(executive.id);

      return Marker(
        markerId: MarkerId(executive.id),
        position: LatLng(executive.latitude, executive.longitude),
        icon:
            _markerIcons[executive.id] ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        consumeTapEvents: true,
        infoWindow: isActive
            ? InfoWindow(title: executive.name, snippet: executive.address)
            : InfoWindow.noText,
        onTap: () => _handleMarkerTap(executive),
        anchor: const Offset(0.5, 1),
        zIndexInt: isActive ? 10 : 1,
      );
    }).toSet();
  }

  Future<void> _prepareMarkerIcons(Color primaryColor) async {
    final futures = _viewModel.fieldExecutives.map((executive) async {
      final icon = await _buildMarkerIcon(
        executive.name,
        primaryColor,
      );
      return MapEntry(executive.id, icon);
    });

    final entries = await Future.wait(futures);
    if (!mounted) return;

    setState(() {
      for (final entry in entries) {
        _markerIcons[entry.key] = entry.value;
      }
    });
  }

  Future<BitmapDescriptor> _buildMarkerIcon(String label, Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',
    )..layout(maxWidth: 250);

    const horizontalPadding = 12.0;
    const bubbleHeight = 45.0;
    const pointerHeight = 10.0;
    const bottomSpacing = 8.0;
    final bubbleWidth = textPainter.width + (horizontalPadding * 2);
    final totalWidth = bubbleWidth < 150 ? 150.0 : bubbleWidth;
    final totalHeight = bubbleHeight + pointerHeight + bottomSpacing;

    final paint = Paint()..color = color;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, totalWidth, bubbleHeight),
      const Radius.circular(22),
    );
    canvas.drawRRect(rect, paint);

    final pointerPath = ui.Path()
      ..moveTo((totalWidth / 2) - 14, bubbleHeight)
      ..lineTo(totalWidth / 2, totalHeight - bottomSpacing)
      ..lineTo((totalWidth / 2) + 14, bubbleHeight)
      ..close();
    canvas.drawPath(pointerPath, paint);

    textPainter.paint(
      canvas,
      Offset(
        (totalWidth - textPainter.width) / 2,
        (bubbleHeight - textPainter.height) / 2,
      ),
    );

    final image = await recorder.endRecording().toImage(
      totalWidth.ceil(),
      totalHeight.ceil(),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData?.buffer.asUint8List();
    if (bytes == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }

    return BitmapDescriptor.bytes(bytes);
  }

  Widget _buildExecutiveDropdown(ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18.sdp),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.12),
            blurRadius: 16.sdp,
            offset: Offset(0, 8.sdp),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.sdp, vertical: 4.sdp),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _viewModel.selectedExecutiveId,
            isExpanded: true,
            borderRadius: BorderRadius.circular(16.sdp),
            icon: const Icon(Icons.keyboard_arrow_down_rounded),
            items: _viewModel.buildExecutiveDropdownItems(),
            onChanged: (value) {
              if (value == null) return;
              _viewModel.selectExecutive(value);
              _syncMapToSelection();
            },
          ),
        ),
      ),
    );
  }

  void _handleMarkerTap(FieldExecutiveLocation executive) {
    _viewModel.activateExecutive(executive.id);
    final controller = _mapController;
    if (controller == null) return;

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(executive.latitude, executive.longitude),
          zoom: 14.8,
        ),
      ),
    );
  }

  void _syncMapToSelection() {
    final controller = _mapController;
    if (!_isMapReady || controller == null) return;

    final visibleExecutives = _viewModel.visibleExecutives;
    if (visibleExecutives.isEmpty) return;

    if (visibleExecutives.length == 1) {
      final executive = visibleExecutives.first;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(executive.latitude, executive.longitude),
            zoom: 12.8,
          ),
        ),
      );
      return;
    }

    final bounds = _viewModel.getVisibleBounds();
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(bounds.minLatitude, bounds.minLongitude),
          northeast: LatLng(bounds.maxLatitude, bounds.maxLongitude),
        ),
        56,
      ),
    );
  }

  LatLng _toGoogleLatLng(({double latitude, double longitude}) location) {
    return LatLng(location.latitude, location.longitude);
  }
}
