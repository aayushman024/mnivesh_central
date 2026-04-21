import 'dart:io';
import 'dart:ui' as ui;
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mnivesh_central/Services/snackBar_Service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Models/marketing_model.dart';
import '../API/api_client.dart';
import '../API/api_config.dart';

class MarketingImageUtil {
  static Dio get _dio => ApiClient.getDio(ApiConfig.defaultBaseUrl);
  static const MethodChannel _galleryChannel = MethodChannel(
    'com.mnivesh.central.mnivesh_central/gallery',
  );

  static Future<ui.Image> _loadImage(String url) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
      ),
    );
    final Uint8List bytes = Uint8List.fromList(response.data!);
    final ui.Codec codec = await ui.instantiateImageCodec(bytes);
    final ui.FrameInfo frame = await codec.getNextFrame();
    return frame.image;
  }

  static Future<ui.Image?> _loadAssetImage(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      final Uint8List bytes = data.buffer.asUint8List();
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      debugPrint('Warning: Could not load asset image $assetPath');
      return null;
    }
  }

  static Future<File?> generateImageFile(MarketingTemplate tpl) async {
    try {
      // 1. Load the main template image
      final mainImg = await _loadImage(tpl.proxyImageUrl);

      // 2. Load the footer asset
      final footerImg = await _loadAssetImage(
        'assets/FooterMarketingTemplate.png',
      );

      // 3. User info
      final prefs = await SharedPreferences.getInstance();
      final String userName = prefs.getString("UserName") ?? "";
      final String userPhone = prefs.getString("workPhone") ?? "";

      // Dimensions logic similar to the web code
      const double minWidth = 2000;
      final double naturalWidth = mainImg.width.toDouble();
      final double scale = naturalWidth < minWidth
          ? minWidth / naturalWidth
          : 1.0;

      final double canvasWidth = naturalWidth * scale;

      final double disclaimerHeight = ((30 * scale).clamp(
        canvasWidth * 0.030,
        double.infinity,
      )).toDouble();

      double footerHeight = 0;
      if (footerImg != null) {
        footerHeight = (footerImg.height / footerImg.width) * canvasWidth;
      }

      final double gapAboveDisclaimer = canvasWidth * 0.005;
      final double mainImgHeight = mainImg.height * scale;

      final double canvasHeight =
          mainImgHeight + gapAboveDisclaimer + disclaimerHeight + footerHeight;

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      );

      // White background fill
      final Paint bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, canvasWidth, canvasHeight), bgPaint);

      // 5. Draw main image
      canvas.drawImageRect(
        mainImg,
        Rect.fromLTWH(
          0,
          0,
          mainImg.width.toDouble(),
          mainImg.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, canvasWidth, mainImgHeight),
        Paint(),
      );

      // 6. Draw Disclaimer Strip
      final double disclaimerY = mainImgHeight + gapAboveDisclaimer;
      canvas.drawRect(
        Rect.fromLTWH(0, disclaimerY, canvasWidth, disclaimerHeight),
        bgPaint,
      );

      final String disclaimerText = 'Disclaimer: ${tpl.disclaimer?.text ?? ""}';
      final double fontSizeDisclaimer = ((9.5 * scale).clamp(
        canvasWidth * 0.013,
        double.infinity,
      )).toDouble();

      final TextSpan span = TextSpan(
        text: disclaimerText,
        style: TextStyle(
          color: const Color(0xFF111827),
          fontSize: fontSizeDisclaimer,
          fontFamily: 'Inter',
        ),
      );
      final TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout(minWidth: canvasWidth, maxWidth: canvasWidth);
      tp.paint(
        canvas,
        Offset(0, disclaimerY + (disclaimerHeight - tp.height) / 2),
      );

      // 7. Draw Footer Image & Text
      if (footerImg != null) {
        final double footerY = disclaimerY + disclaimerHeight;
        canvas.drawImageRect(
          footerImg,
          Rect.fromLTWH(
            0,
            0,
            footerImg.width.toDouble(),
            footerImg.height.toDouble(),
          ),
          Rect.fromLTWH(0, footerY, canvasWidth, footerHeight),
          Paint(),
        );

        final double fontSizeFooter = ((14 * scale).clamp(
          canvasWidth * 0.018,
          double.infinity,
        )).toDouble();
        final TextStyle footerStyle = TextStyle(
          color: const Color(0xFF111827),
          fontSize: fontSizeFooter,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        );

        final double textX = canvasWidth * 0.65;
        final double nameY = footerY + footerHeight * 0.06;
        final double phoneY = footerY + footerHeight * 0.36;

        final TextPainter nameTp = TextPainter(
          text: TextSpan(text: userName, style: footerStyle),
          textDirection: TextDirection.ltr,
        );
        nameTp.layout();
        nameTp.paint(canvas, Offset(textX, nameY));

        final String displayPhone = userPhone.isNotEmpty
            ? '+91 $userPhone'
            : '';
        final TextPainter phoneTp = TextPainter(
          text: TextSpan(text: displayPhone, style: footerStyle),
          textDirection: TextDirection.ltr,
        );
        phoneTp.layout();
        phoneTp.paint(canvas, Offset(textX, phoneY));
      }

      final ui.Picture picture = recorder.endRecording();
      final ui.Image finalImage = await picture.toImage(
        canvasWidth.toInt(),
        canvasHeight.toInt(),
      );

      final ByteData? byteData = await finalImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final Directory tempDir = await getTemporaryDirectory();
      final Directory shareCacheDir = Directory('${tempDir.path}/share_cache');
      if (!await shareCacheDir.exists()) {
        await shareCacheDir.create(recursive: true);
      }

      final String fileName =
          'marketing_${DateTime.now().millisecondsSinceEpoch}.png';
      final File file = File('${shareCacheDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      return file;
    } catch (e) {
      debugPrint('Error generating canvas image: $e');
      return null;
    }
  }

  static Future<bool> shareFile(File file, {required String text}) async {
    try {
      final result = await Share.shareXFiles([XFile(file.path)], text: text);
      // clean up immediately
      if (await file.exists()) {
        await file.delete();
      }
      return result.status == ShareResultStatus.success;
    } catch (e) {
      debugPrint('Error sharing file: $e');
      return false;
    }
  }

  static Future<void> saveToGallery(File file, String title) async {
    try {
      await _requestGalleryPermissionIfNeeded();

      final bytes = await file.readAsBytes();
      final savedPath = await _galleryChannel.invokeMethod<String>(
        'saveImage',
        {'bytes': bytes, 'title': _sanitizeFileName(title)},
      );

      if (savedPath == null || savedPath.isEmpty) {
        SnackbarService.showError('Could not download image');
        throw Exception('Gallery save did not return a file path.');
      }
      SnackbarService.showSuccess('Image Downloaded at $savedPath');
    } finally {
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  static Future<void> _requestGalleryPermissionIfNeeded() async {
    if (Platform.isIOS) {
      final status = await Permission.photosAddOnly.request();
      if (!status.isGranted && !status.isLimited) {
        throw Exception('Photos permission not granted.');
      }
      return;
    }

    if (!Platform.isAndroid) return;

    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 29) {
      return;
    }

    final status = await Permission.storage.request();
    if (!status.isGranted) {
      throw Exception('Storage permission not granted.');
    }
  }

  static String _sanitizeFileName(String value) {
    final sanitized = value
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .trim();
    return sanitized.isEmpty ? 'marketing_template' : sanitized;
  }
}
