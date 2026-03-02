// lib/ViewModels/mfTransaction_viewModel.dart

import 'package:flutter_riverpod/legacy.dart';

import '../Models/mftrans_models.dart';
import '../Services/snackBar_Service.dart';

// ─────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────

enum TransPref { asap, nextWorkingDay, custom }

// ─────────────────────────────────────────────
// State
// ─────────────────────────────────────────────

class MfTransactionState {
  final TransPref preference;
  final bool isSearchingUcc;
  final bool showUcc;
  final DateTime? selectedDate;
  final InvestorModel? selectedInvestor;
  final List<UccModel> uccData;
  final String? selectedUccId;

  const MfTransactionState({
    this.preference = TransPref.asap,
    this.isSearchingUcc = false,
    this.showUcc = false,
    this.selectedDate,
    this.selectedInvestor,
    this.uccData = const [],
    this.selectedUccId,
  });

  MfTransactionState copyWith({
    TransPref? preference,
    bool? isSearchingUcc,
    bool? showUcc,
    DateTime? selectedDate,
    InvestorModel? selectedInvestor,
    List<UccModel>? uccData,
    String? selectedUccId,
    bool clearUccSelection = false,
    bool clearInvestor = false,
  }) {
    return MfTransactionState(
      preference: preference ?? this.preference,
      isSearchingUcc: isSearchingUcc ?? this.isSearchingUcc,
      showUcc: showUcc ?? this.showUcc,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedInvestor: clearInvestor
          ? null
          : (selectedInvestor ?? this.selectedInvestor),
      uccData: uccData ?? this.uccData,
      selectedUccId: clearUccSelection
          ? null
          : (selectedUccId ?? this.selectedUccId),
    );
  }
}

// ─────────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────────

class MfTransactionViewModel extends StateNotifier<MfTransactionState> {
  MfTransactionViewModel()
    : super(MfTransactionState(selectedDate: _defaultDateTime()));

  // ── Mock data (replace with repository calls) ──────────────────────────────

  final List<InvestorModel> _mockInvestors = const [
    InvestorModel(
      name: 'ATUL BHAMBRI',
      pan: 'ABCDE1234F',
      familyHead: 'ATUL BHAMBRI',
    ),
    InvestorModel(name: 'JOHN DOE', pan: 'QWERT9876X', familyHead: 'JOHN DOE'),
    InvestorModel(
      name: 'A R COMPUTERS',
      pan: 'ZXCVB5432M',
      familyHead: 'ALICE R',
    ),
  ];

  // ── Helpers ────────────────────────────────────────────────────────────────

  static DateTime _defaultDateTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 10, 0);
  }

  DateTime _nextWorkingDay() {
    DateTime next = DateTime.now().add(const Duration(days: 1));
    if (next.weekday == DateTime.sunday)
      next = next.add(const Duration(days: 1));
    return DateTime(next.year, next.month, next.day, 10, 0);
  }

  // ── Preference & Date ──────────────────────────────────────────────────────

  void setPreference(TransPref pref) {
    final date = pref == TransPref.nextWorkingDay
        ? _nextWorkingDay()
        : state.selectedDate;
    state = state.copyWith(preference: pref, selectedDate: date);
  }

  void setDate(DateTime date) => state = state.copyWith(selectedDate: date);

  // ── Investor Search ────────────────────────────────────────────────────────

  Future<List<InvestorModel>> searchByName(String query) async {
    if (query.isEmpty) return [];
    // TODO: replace with repository.searchByName(query)
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockInvestors
        .where((i) => i.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<List<InvestorModel>> searchByPan(String query) async {
    if (query.isEmpty) return [];
    // TODO: replace with repository.searchByPan(query)
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockInvestors
        .where((i) => i.pan.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<List<InvestorModel>> searchByFamilyHead(String query) async {
    if (query.isEmpty) return [];
    // TODO: replace with repository.searchByFamilyHead(query)
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockInvestors
        .where((i) => i.familyHead.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void selectInvestor(InvestorModel investor) {
    state = state.copyWith(selectedInvestor: investor);
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  /// Returns true if valid; shows snackbar error and returns false otherwise.
  bool validateStep1() {
    if (state.selectedInvestor == null) {
      SnackbarService.showError('Please search and select an investor.');
      return false;
    }
    if (state.selectedUccId == null) {
      SnackbarService.showError('Please select a UCC before proceeding.');
      return false;
    }
    return true;
  }

  // ── UCC ────────────────────────────────────────────────────────────────────

  Future<void> fetchUccData() async {
    if (state.selectedInvestor == null) {
      SnackbarService.showError('Please select an investor first.');
      return;
    }

    state = state.copyWith(
      isSearchingUcc: true,
      showUcc: false,
      clearUccSelection: true,
    );

    // TODO: replace with repository.fetchUcc(state.selectedInvestor!.pan)
    await Future.delayed(const Duration(seconds: 1));

    const mockData = [
      UccModel(
        name: 'Atul Bhambri',
        id: 'AFBPB5026P',
        bseStatus: 'Active',
        bank: 'BANK/7656',
        nominee: 'Yes',
        isValidated: true,
      ),
      UccModel(
        name: 'A R Computers',
        id: 'AFBPB5PROP',
        bseStatus: 'Inactive',
        bank: 'SOUTH/2631',
        nominee: 'No',
        isValidated: true,
      ),
    ];

    state = state.copyWith(
      isSearchingUcc: false,
      showUcc: true,
      uccData: mockData,
    );
  }

  void selectUcc(String id) => state = state.copyWith(selectedUccId: id);

  void deselectUcc() => state = state.copyWith(clearUccSelection: true);
}

// ─────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────

final mfTransactionProvider =
    StateNotifierProvider<MfTransactionViewModel, MfTransactionState>(
      (ref) => MfTransactionViewModel(),
    );
