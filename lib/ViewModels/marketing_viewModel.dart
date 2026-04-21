import 'dart:io';

import 'package:flutter/material.dart';

import '../API/marketing_api_service.dart';
import '../Models/marketing_model.dart';
import '../Utils/marketing_image_util.dart';

class MarketingSectionData {
  final String title;
  final List<MarketingTemplate> templates;

  MarketingSectionData({required this.title, required this.templates});
}

class MarketingViewModel extends ChangeNotifier {
  bool isLoading = false;
  List<MarketingSectionData> sections = [];
  
  List<MarketingCategory> categories = [];
  String? selectedCategoryKey;

  Future<void> loadData() async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch categories
      final options = await MarketingApiService.getMarketingOptions();
      categories = options.categories;

      // 2. Fetch templates
      await fetchTemplates();
    } catch (e) {
      debugPrint('Error loading marketing data: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTemplates() async {
    isLoading = true;
    notifyListeners();

    try {
      final templates = await MarketingApiService.getMarketingTemplates(selectedCategoryKey);
      
      // Group by Category label Let's preserve order of templates return from backend
      final Map<String, List<MarketingTemplate>> grouped = {};
      for (final tpl in templates) {
        final label = tpl.category?.label ?? 'Marketing';
        if (!grouped.containsKey(label)) {
          grouped[label] = [];
        }
        grouped[label]!.add(tpl);
      }

      // If selectedCategoryKey is present, ensure that category is first in the list
      final sortedEntries = grouped.entries.toList();
      if (selectedCategoryKey != null) {
        final selectedCat = categories.firstWhere(
            (c) => c.key == selectedCategoryKey,
            orElse: () => MarketingCategory(id: '', key: '', label: ''));
        sortedEntries.sort((a, b) {
          if (a.key == selectedCat.label) return -1;
          if (b.key == selectedCat.label) return 1;
          return 0;
        });
      }

      sections = sortedEntries
          .map((entry) => MarketingSectionData(title: entry.key, templates: entry.value))
          .toList();
    } catch (e) {
      debugPrint('Error fetching marketing templates: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void onCategorySelected(String? categoryKey) {
    if (selectedCategoryKey == categoryKey) return;
    selectedCategoryKey = categoryKey;
    fetchTemplates();
  }


  Future<bool> shareImage(MarketingTemplate template, {String? shareText}) async {
    try {
      final resultFile = await MarketingImageUtil.generateImageFile(template);
      if (resultFile == null) return false;

      final result = await MarketingImageUtil.shareFile(
        resultFile, 
        text: shareText ?? 'Check out this marketing material!'
      );
      return result;
    } catch (e) {
      debugPrint('Unexpected error during share: $e');
      return false;
    }
  }

  Future<void> downloadImage(MarketingTemplate template) async {
    debugPrint('Downloading: ${template.proxyImageUrl}');
    try {
        final resultFile = await MarketingImageUtil.generateImageFile(template);
        if (resultFile != null) {
           await MarketingImageUtil.saveToGallery(resultFile, template.title);
        }
    } catch (e) {
        debugPrint('Error downloading image: $e');
    }
  }
}

