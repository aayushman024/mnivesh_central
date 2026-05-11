import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../Models/route_optimization_models.dart';
import '../../../Themes/AppTextStyle.dart';
import '../../../Utils/Dimensions.dart';
import '../../../ViewModels/routeOptimization_viewModel.dart';
import '../../Widgets/ModuleAppBar.dart';

class FieldExecutiveTrackingScreen extends StatefulWidget {
  const FieldExecutiveTrackingScreen({super.key});

  @override
  State<FieldExecutiveTrackingScreen> createState() => _FieldExecutiveTrackingScreenState();
}

class _FieldExecutiveTrackingScreenState extends State<FieldExecutiveTrackingScreen> {
  late final RouteOptimizationViewModel _viewModel;
  GoogleMapController? _mapController;
  final Map<String, BitmapDescriptor> _markerIcons = {};
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _viewModel = RouteOptimizationViewModel();
    _viewModel.addListener(_handleViewModelUpdate);
    Future.microtask(_viewModel.loadTrackingData);
  }

  void _handleViewModelUpdate() {
    if (_viewModel.fieldExecutives.isNotEmpty) {
      final existingIds = _markerIcons.keys.toSet();
      final currentIds = _viewModel.fieldExecutives.map((e) => e.id).toSet();
      if (!existingIds.containsAll(currentIds)) {
        _prepareMarkerIcons(Theme.of(context).colorScheme.primary);
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _viewModel.removeListener(_handleViewModelUpdate);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SizeUtil.init(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ModuleAppBar(title: 'Track Field Executives', isBackIcon: true),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isTrackingLoading && _viewModel.fieldExecutives.isEmpty) return const Center(child: CircularProgressIndicator());
          if (_viewModel.trackingErrorMessage != null && _viewModel.fieldExecutives.isEmpty) {
            return _TrackingStateView(title: 'Unable to load FE locations', message: _viewModel.trackingErrorMessage!, actionLabel: 'Retry', onPressed: _viewModel.loadTrackingData);
          }
          if (_viewModel.fieldExecutives.isEmpty) {
            return _TrackingStateView(title: 'No live executives found', message: 'Active field executives with live route data will appear here.', actionLabel: 'Refresh', onPressed: _viewModel.loadTrackingData);
          }

          return Stack(
            children: [
              _buildMap(theme),
              _buildDropdownOverlay(theme),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.only(top: 35.sdp),
      child: Container(
        decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10.sdp, spreadRadius: 1)]),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.sdp)),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: _toLatLng(_viewModel.getInitialCenter()), zoom: _viewModel.getInitialZoom()),
            onMapCreated: (c) { _mapController = c; _isMapReady = true; _syncMapToSelection(); },
            markers: _buildMarkers(theme),
            zoomControlsEnabled: true,
            myLocationButtonEnabled: false,
            colorScheme: MapColorScheme.dark,
            minMaxZoomPreference: const MinMaxZoomPreference(4, 17),
            padding: EdgeInsets.only(top: 88.sdp),
            onTap: (_) => _viewModel.clearActiveExecutive(),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownOverlay(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(26.sdp, 12.sdp, 26.sdp, 0),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.96),
            borderRadius: BorderRadius.circular(18.sdp),
            border: Border.all(color: theme.colorScheme.outline.withOpacity(0.15)),
            boxShadow: [BoxShadow(color: theme.colorScheme.shadow.withOpacity(0.2), blurRadius: 16.sdp, offset: Offset(0, 6.sdp))],
          ),
          padding: EdgeInsets.symmetric(horizontal: 14.sdp, vertical: 4.sdp),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _viewModel.selectedExecutiveId,
              isExpanded: true,
              borderRadius: BorderRadius.circular(16.sdp),
              items: _viewModel.buildExecutiveDropdownItems(),
              onChanged: (val) { if (val != null) { _viewModel.selectExecutive(val); _syncMapToSelection(); } },
            ),
          ),
        ),
      ),
    );
  }

  Set<Marker> _buildMarkers(ThemeData theme) {
    final markers = <Marker>{};
    for (final exec in _viewModel.visibleExecutives) {
      final isActive = _viewModel.isMarkerActive(exec.id);
      markers.add(Marker(
        markerId: MarkerId(exec.id),
        position: LatLng(exec.latest.latitude, exec.latest.longitude),
        icon: _markerIcons[exec.id] ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        consumeTapEvents: true,
        infoWindow: isActive ? InfoWindow(title: exec.name, snippet: exec.latest.address) : InfoWindow.noText,
        onTap: () => _handleMarkerTap(exec),
        anchor: const Offset(0.5, 1),
        zIndexInt: isActive ? 10 : 1,
      ));

      if (isActive && exec.clientLocation != null) {
        markers.add(Marker(
          markerId: MarkerId('client_${exec.id}'),
          position: LatLng(exec.clientLocation!.latitude, exec.clientLocation!.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Client Location'),
        ));
      }
    }
    return markers;
  }

  void _handleMarkerTap(FieldExecutiveLocation exec) {
    _viewModel.activateExecutive(exec.id);
    _mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(exec.latest.latitude, exec.latest.longitude), zoom: 14.8)));
    _showDetailsSheet(exec);
  }

  void _showDetailsSheet(FieldExecutiveLocation exec) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeFormat = DateFormat('hh:mm a');
    final dateFormat = DateFormat('hh:mm a, dd MMM');
    final history = exec.history.toList()..sort((a, b) => (b.timestamp ?? DateTime.now()).compareTo(a.timestamp ?? DateTime.now()));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: EdgeInsets.fromLTRB(20.sdp, 12.sdp, 20.sdp, 32.sdp),
        decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28.sdp))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40.sdp, height: 4.sdp, decoration: BoxDecoration(color: colorScheme.outline.withOpacity(0.2), borderRadius: BorderRadius.circular(2.sdp)))),
            SizedBox(height: 20.sdp),
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(exec.name, style: AppTextStyle.extraBold.custom(20.ssp, colorScheme.onSurface)),
                  Text('ID: ${exec.employeeId}', style: AppTextStyle.bold.custom(13.ssp, colorScheme.onSurfaceVariant)),
                ])),
                _buildBatteryIndicator(exec.latest.batteryPercentage, large: true),
              ],
            ),
            SizedBox(height: 24.sdp),
            Flexible(child: SingleChildScrollView(child: Column(children: [
              _buildInfoRow(PhosphorIcons.clock(), 'Latest Update', exec.latest.timestamp != null ? dateFormat.format(exec.latest.timestamp!) : 'N/A'),
              SizedBox(height: 16.sdp),
              _buildInfoRow(PhosphorIcons.mapPin(), 'Current Location', exec.latest.address),
              if (history.isNotEmpty) ...[
                SizedBox(height: 32.sdp),
                Align(alignment: Alignment.centerLeft, child: Text('Location History (Past 2 Hours)', style: AppTextStyle.bold.custom(15.ssp, colorScheme.onSurface))),
                SizedBox(height: 16.sdp),
                ...history.map((h) => _buildHistoryItem(h, timeFormat)),
              ]
            ])))
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(LocationUpdate update, DateFormat format) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 12.sdp),
      padding: EdgeInsets.all(12.sdp),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12.sdp),
        border: Border.all(color: theme.brightness == Brightness.dark ? const Color(0xFF334155).withOpacity(0.3) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Column(children: [
            Text(update.timestamp != null ? format.format(update.timestamp!) : '--:--', style: AppTextStyle.bold.custom(12.ssp, theme.colorScheme.primary)),
            if (update.batteryPercentage != null) _buildBatteryIndicator(update.batteryPercentage, large: false),
          ]),
          SizedBox(width: 16.sdp),
          Expanded(child: Text(update.address, style: AppTextStyle.normal.custom(12.ssp, theme.colorScheme.onSurface), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildBatteryIndicator(int? percentage, {required bool large}) {
    if (percentage == null) return const SizedBox.shrink();
    final color = percentage > 70 ? Colors.green : (percentage > 20 ? Colors.orange : Colors.red);
    final icon = percentage > 70 ? PhosphorIcons.batteryFull() : (percentage > 20 ? PhosphorIcons.batteryMedium() : PhosphorIcons.batteryLow());
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12.sdp : 10.sdp, vertical: large ? 8.sdp : 4.sdp),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12.sdp), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [Icon(icon, color: color, size: large ? 18.sdp : 14.sdp), SizedBox(width: 8.sdp), Text('$percentage%', style: AppTextStyle.extraBold.custom(large ? 14.ssp : 12.ssp, color))]),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(14.sdp),
      decoration: BoxDecoration(color: colorScheme.surfaceVariant.withOpacity(0.2), borderRadius: BorderRadius.circular(16.sdp), border: Border.all(color: colorScheme.outline.withOpacity(0.1))),
      child: Row(children: [
        Icon(icon, color: colorScheme.primary, size: 20.sdp),
        SizedBox(width: 14.sdp),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTextStyle.bold.custom(11.ssp, colorScheme.primary)),
          Text(value, style: AppTextStyle.normal.custom(14.ssp, colorScheme.onSurface)),
        ])),
      ]),
    );
  }

  void _syncMapToSelection() {
    if (!_isMapReady || _mapController == null) return;
    final visible = _viewModel.visibleExecutives;
    if (visible.isEmpty) return;
    if (visible.length == 1) {
      _mapController!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: LatLng(visible.first.latest.latitude, visible.first.latest.longitude), zoom: 12.8)));
    } else {
      final bounds = _viewModel.getVisibleBounds();
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: LatLng(bounds.minLatitude, bounds.minLongitude), northeast: LatLng(bounds.maxLatitude, bounds.maxLongitude)), 56));
    }
  }

  LatLng _toLatLng(({double latitude, double longitude}) loc) => LatLng(loc.latitude, loc.longitude);

  Future<void> _prepareMarkerIcons(Color color) async {
    for (final exec in _viewModel.fieldExecutives) {
      _markerIcons[exec.id] = await _buildMarkerIcon(exec.name, color);
    }
    if (mounted) setState(() {});
  }

  Future<BitmapDescriptor> _buildMarkerIcon(String label, Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final textPainter = TextPainter(text: TextSpan(text: label, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)), textDirection: ui.TextDirection.ltr, maxLines: 1, ellipsis: '...')..layout(maxWidth: 250);
    final width = (textPainter.width + 24).clamp(150.0, 300.0);
    const height = 45.0;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, width, height), const Radius.circular(22)), Paint()..color = color);
    final path = ui.Path()..moveTo(width / 2 - 14, height)..lineTo(width / 2, height + 10)..lineTo(width / 2 + 14, height)..close();
    canvas.drawPath(path, Paint()..color = color);
    textPainter.paint(canvas, Offset((width - textPainter.width) / 2, (height - textPainter.height) / 2));
    final image = await recorder.endRecording().toImage(width.ceil(), (height + 18).ceil());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data != null ? BitmapDescriptor.bytes(data.buffer.asUint8List()) : BitmapDescriptor.defaultMarker;
  }
}

class _TrackingStateView extends StatelessWidget {
  final String title, message, actionLabel;
  final Future<void> Function() onPressed;
  const _TrackingStateView({required this.title, required this.message, required this.actionLabel, required this.onPressed});
  @override
  Widget build(BuildContext context) {
    return Center(child: Padding(padding: EdgeInsets.all(24.sdp), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(title, textAlign: TextAlign.center, style: AppTextStyle.extraBold.custom(18.ssp, Theme.of(context).colorScheme.onSurface)),
      SizedBox(height: 10.sdp),
      Text(message, textAlign: TextAlign.center, style: AppTextStyle.normal.custom(13.ssp, Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
      SizedBox(height: 18.sdp),
      FilledButton(onPressed: onPressed, child: Text(actionLabel)),
    ])));
  }
}
