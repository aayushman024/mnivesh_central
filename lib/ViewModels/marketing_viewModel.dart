import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../Models/marketing_model.dart';

class MarketingViewModel extends ChangeNotifier {
  bool isLoading = false;
  List<MarketingSectionData> sections = [];
  final Dio _dio = Dio(); // Reuse dio instance if you have a global one

  Future<void> loadData() async {
    isLoading = true;
    notifyListeners();

    // Mock API delay
    await Future.delayed(const Duration(milliseconds: 500));

    sections = [
      MarketingSectionData(
        title: 'Marketing Collateral',
        imageUrls: [
          'https://via.placeholder.com/400x500.png?text=Koti+Suraksha',
          'https://via.placeholder.com/400x500.png?text=Star+Accident+Care',
          'https://via.placeholder.com/400x500.png?text=HDFC+Ergo',
        ],
      ),
      MarketingSectionData(
        title: 'Marketing',
        imageUrls: [
          'https://via.placeholder.com/400x500.png?text=Koti+Suraksha+2',
          'https://via.placeholder.com/400x500.png?text=Star+Accident+Care+2',
        ],
      ),
    ];

    isLoading = false;
    notifyListeners();
  }

  Future<void> shareImage(String imageUrl) async {
    try {
      // 1. Fetch image bytes using Dio
      final response = await _dio.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.statusCode != 200 || response.data == null) {
        debugPrint(
          'Failed to fetch image for sharing: HTTP ${response.statusCode}',
        );
        return;
      }

      // 2. Get temp dir to stash the file temporarily
      final tempDir = await getTemporaryDirectory();

      final fileName = 'share_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');

      // 3. Write bytes to disk
      await file.writeAsBytes(response.data!);

      // 4. Trigger native share sheet
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Check out this marketing material!');
    } catch (e) {
      debugPrint('Error sharing image: $e');
    }
  }

  Future<void> downloadImage(String imageUrl) async {
    // TODO: implement image_gallery_saver logic
    debugPrint('Downloading: $imageUrl');
  }
}
