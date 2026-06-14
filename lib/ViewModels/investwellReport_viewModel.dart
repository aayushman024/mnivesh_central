import 'dart:io';
import 'package:flutter_riverpod/legacy.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../API/api_service.dart';
import '../Models/investwell_report_models.dart';
import '../Services/snackBar_Service.dart';
import '../Utils/marketing_image_util.dart';

class InvestwellReportState {
  final InvestwellInvestorModel? selectedInvestor;
  final InvestwellReportType selectedType;
  final int? selectedYear;
  final InvestwellReportFile? reportFile;
  final bool isLoading;
  final String? errorText;
  final bool isFiltersExpanded;
  final bool searchAll;
  final String searchQuery;
  final List<int> years;

  const InvestwellReportState({
    this.selectedInvestor,
    this.selectedType = InvestwellReportType.capitalGain,
    this.selectedYear,
    this.reportFile,
    this.isLoading = false,
    this.errorText,
    this.isFiltersExpanded = true,
    this.searchAll = false,
    this.searchQuery = '',
    required this.years,
  });

  InvestwellReportState copyWith({
    bool clearInvestor = false,
    InvestwellInvestorModel? selectedInvestor,
    InvestwellReportType? selectedType,
    bool clearYear = false,
    int? selectedYear,
    bool clearReportFile = false,
    InvestwellReportFile? reportFile,
    bool? isLoading,
    bool clearErrorText = false,
    String? errorText,
    bool? isFiltersExpanded,
    bool? searchAll,
    bool clearSearchQuery = false,
    String? searchQuery,
    List<int>? years,
  }) {
    return InvestwellReportState(
      selectedInvestor: clearInvestor
          ? null
          : (selectedInvestor ?? this.selectedInvestor),
      selectedType: selectedType ?? this.selectedType,
      selectedYear: clearYear ? null : (selectedYear ?? this.selectedYear),
      reportFile: clearReportFile ? null : (reportFile ?? this.reportFile),
      isLoading: isLoading ?? this.isLoading,
      errorText: clearErrorText ? null : (errorText ?? this.errorText),
      isFiltersExpanded: isFiltersExpanded ?? this.isFiltersExpanded,
      searchAll: searchAll ?? this.searchAll,
      searchQuery: clearSearchQuery ? '' : (searchQuery ?? this.searchQuery),
      years: years ?? this.years,
    );
  }
}

class InvestwellReportViewModel extends StateNotifier<InvestwellReportState> {
  InvestwellReportViewModel()
    : super(
        InvestwellReportState(
          selectedYear: DateTime.now().year,
          years: List<int>.generate(3, (index) => DateTime.now().year - index),
        ),
      );

  void setSelectedInvestor(InvestwellInvestorModel? investor) {
    state = state.copyWith(
      selectedInvestor: investor,
      clearInvestor: investor == null,
      searchQuery: investor?.name ?? state.searchQuery,
      clearReportFile: true,
      clearErrorText: true,
    );
  }

  void setSelectedType(InvestwellReportType type) {
    if (state.selectedType == type) return;
    state = state.copyWith(
      selectedType: type,
      clearReportFile: true,
      clearErrorText: true,
    );
  }

  void setSelectedYear(int? year) {
    if (state.selectedYear == year) return;
    state = state.copyWith(
      selectedYear: year,
      clearYear: year == null,
      clearReportFile: true,
      clearErrorText: true,
    );
  }

  Future<void> fetchReport({required void Function(String) onError}) async {
    final investor = state.selectedInvestor;
    if (investor == null) {
      onError('Please select an investor.');
      return;
    }
    if (state.selectedType == InvestwellReportType.capitalGain &&
        state.selectedYear == null) {
      onError('Please select a year.');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      clearErrorText: true,
      clearReportFile: true,
    );

    try {
      final report = await ApiService.fetchInvestwellReport(
        InvestwellReportRequest(
          type: state.selectedType,
          pan: investor.pan,
          year: state.selectedType == InvestwellReportType.capitalGain
              ? state.selectedYear
              : null,
        ),
      );
      state = state.copyWith(
        reportFile: report,
        isLoading: false,
        isFiltersExpanded: false,
      );
    } catch (e) {
      state = state.copyWith(errorText: e.toString(), isLoading: false);
    }
  }

  void toggleFilters() {
    state = state.copyWith(isFiltersExpanded: !state.isFiltersExpanded);
  }

  void toggleSearchAll(bool? value) {
    if (value != null) {
      state = state.copyWith(searchAll: value);
    }
  }

  void setSearchQuery(String value) {
    final normalizedValue = value.trim();
    if (state.searchQuery == normalizedValue) return;
    state = state.copyWith(searchQuery: normalizedValue);
  }

  Future<void> shareReport() async {
    if (state.reportFile == null) return;
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${state.reportFile!.fileName}');
      await tempFile.writeAsBytes(state.reportFile!.bytes);
      
      await MarketingImageUtil.shareFile(
        tempFile,
        text: 'Please find attached the report: ${state.reportFile!.fileName}',
      );
    } catch (e) {
      SnackbarService.showError('Error sharing report: $e');
    }
  }

  Future<void> downloadReport() async {
    if (state.reportFile == null) return;
    try {
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        SnackbarService.showError('Could not access storage directory');
        return;
      }

      final tempFile = File('${directory.path}/${state.reportFile!.fileName}.pdf');
      await tempFile.writeAsBytes(state.reportFile!.bytes);
      
      SnackbarService.showSuccess('Downloaded to ${tempFile.path}');
      await OpenFilex.open(tempFile.path);
    } catch (e) {
      SnackbarService.showError('Error downloading report: $e');
    }
  }
}

final investwellReportViewModelProvider =
    StateNotifierProvider.autoDispose<
      InvestwellReportViewModel,
      InvestwellReportState
    >((ref) {
      return InvestwellReportViewModel();
    });
