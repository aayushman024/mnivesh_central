import 'dart:io';

import 'package:flutter/material.dart';

import 'package:mnivesh_central/features/marketing/api/marketing_api_service.dart';
import 'package:mnivesh_central/features/marketing/models/marketing_model.dart';
import 'package:mnivesh_central/features/marketing/utils/marketing_image_util.dart';

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
  List<MarketingTemplate> _allTemplates = [];
  
  bool _isEodCategoryKey(String? key) =>
      key?.trim().toLowerCase() == 'eod';

  Future<void> loadData() async {
    if (isLoading) return;
    isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch categories
      final options = await MarketingApiService.getMarketingOptions();
      categories = options.categories;
      
      // Sort categories to show 'eod' first
      categories.sort((a, b) {
        if (_isEodCategoryKey(a.key)) return -1;
        if (_isEodCategoryKey(b.key)) return 1;
        return 0;
      });

      // 2. Fetch templates
      await loadTemplates();
    } catch (e) {
      debugPrint('Error loading marketing data: $e');
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTemplates() async {
    isLoading = true;
    notifyListeners();

    try {
      // Fetch all templates once
      _allTemplates = await MarketingApiService.getMarketingTemplates(null);
      _updateSections();
    } catch (e) {
      debugPrint('Error fetching marketing templates: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _updateSections() {
    // Filter templates locally based on selectedCategoryKey
    final filteredTemplates = selectedCategoryKey == null
        ? _allTemplates
        : _allTemplates
            .where((t) => t.category?.key == selectedCategoryKey)
            .toList();

    // Group by Category label
    final Map<String, List<MarketingTemplate>> grouped = {};
    for (final tpl in filteredTemplates) {
      final label = tpl.category?.label ?? 'Marketing';
      if (!grouped.containsKey(label)) {
        grouped[label] = [];
      }
      grouped[label]!.add(tpl);
    }

    // Priority sorting: 1. Selected Category, 2. EOD Category
    final sortedEntries = grouped.entries.toList();

    final String? selectedLabel = selectedCategoryKey != null
        ? categories
            .firstWhere((c) => c.key == selectedCategoryKey,
                orElse: () => MarketingCategory(id: '', key: '', label: ''))
            .label
        : null;

    // EOD is not returned by the categories API, so derive its label
    // directly from the templates that have an EOD category key.
    final String eodLabel = filteredTemplates
        .firstWhere((t) => _isEodCategoryKey(t.category?.key),
            orElse: () => MarketingTemplate(
                  id: '',
                  title: '',
                  description: '',
                  proxyImageUrl: '',
                  publishDate: DateTime.now(),
                ))
        .category
        ?.label ?? '';

    sortedEntries.sort((a, b) {
      // Selected category takes highest priority
      if (selectedLabel != null) {
        if (a.key == selectedLabel) return -1;
        if (b.key == selectedLabel) return 1;
      }

      // EOD category takes second priority (or first if nothing selected)
      if (eodLabel.isNotEmpty) {
        if (a.key == eodLabel) return -1;
        if (b.key == eodLabel) return 1;
      }

      return 0;
    });

    sections = sortedEntries
        .map((entry) =>
            MarketingSectionData(title: entry.key, templates: entry.value))
        .toList();
    notifyListeners();
  }

  void onCategorySelected(String? categoryKey) {
    if (selectedCategoryKey == categoryKey) return;
    selectedCategoryKey = categoryKey;
    _updateSections();
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

