import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../API/operations_apiService.dart';
import '../Models/mftrans_models.dart';
import '../Services/snackBar_Service.dart';

enum TransPref { asap, nextWorkingDay, customDate, customeDateTime }

class MfTransactionState {
  final TransPref preference;
  final bool searchAllInvestors;
  final bool isSearchingUcc;
  final bool showUcc;
  final DateTime? selectedDate;
  final InvestorModel? selectedInvestor;
  final List<UccModel> uccData;
  final String? selectedUccId;

  const MfTransactionState({
    this.preference = TransPref.asap,
    this.searchAllInvestors = false,
    this.isSearchingUcc = false,
    this.showUcc = false,
    this.selectedDate,
    this.selectedInvestor,
    this.uccData = const [],
    this.selectedUccId,
  });

  MfTransactionState copyWith({
    TransPref? preference,
    bool? searchAllInvestors,
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
      searchAllInvestors: searchAllInvestors ?? this.searchAllInvestors,
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

class MfTransactionViewModel extends StateNotifier<MfTransactionState> {
  MfTransactionViewModel()
    : super(MfTransactionState(selectedDate: _defaultDateTime()));

  int _activeUccRequestId = 0;

  static DateTime _defaultDateTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 10, 0);
  }

  DateTime _nextWorkingDay() {
    DateTime next = DateTime.now().add(const Duration(days: 1));
    if (next.weekday == DateTime.sunday) {
      next = next.add(const Duration(days: 1));
    }
    return DateTime(next.year, next.month, next.day, 10, 0);
  }

  void setPreference(TransPref pref) {
    DateTime? date;

    if (pref == TransPref.nextWorkingDay) {
      date = _nextWorkingDay();
    } else if (pref == TransPref.asap) {
      date = _defaultDateTime();
    } else if (pref == TransPref.customDate) {
      final now = DateTime.now();
      date = DateTime(now.year, now.month, now.day);
    } else if (pref == TransPref.customeDateTime) {
      date = _defaultDateTime();
    }

    state = state.copyWith(preference: pref, selectedDate: date);
  }

  void setDate(DateTime date) => state = state.copyWith(selectedDate: date);

  void setSearchAllInvestors(bool value) {
    state = state.copyWith(searchAllInvestors: value);
  }

  Future<List<InvestorModel>> searchByName(String query) async {
    return _searchInvestors(name: query);
  }

  Future<List<InvestorModel>> searchByPan(String query) async {
    return _searchInvestors(pan: query);
  }

  Future<List<InvestorModel>> searchByFamilyHead(String query) async {
    return _searchInvestors(familyHead: query);
  }

  Future<List<InvestorModel>> _searchInvestors({
    String? name,
    String? pan,
    String? familyHead,
  }) async {
    final normalizedName = name?.trim() ?? '';
    final normalizedPan = pan?.trim() ?? '';
    final normalizedFamilyHead = familyHead?.trim() ?? '';

    if (normalizedName.isEmpty &&
        normalizedPan.isEmpty &&
        normalizedFamilyHead.isEmpty) {
      return const [];
    }

    try {
      return await OperationsApiService.searchInvestors(
        name: normalizedName.isEmpty ? null : normalizedName,
        pan: normalizedPan.isEmpty ? null : normalizedPan,
        familyHead: normalizedFamilyHead.isEmpty ? null : normalizedFamilyHead,
        searchAll: state.searchAllInvestors,
      );
    } catch (error) {
      debugPrint('[MfTransactionViewModel] Investor search failed: $error');
      return const [];
    }
  }

  void selectInvestor(InvestorModel investor) {
    _activeUccRequestId++;
    state = state.copyWith(
      selectedInvestor: investor,
      showUcc: false,
      uccData: const [],
      clearUccSelection: true,
    );
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void clearInvestorSelection() {
    _activeUccRequestId++;
    state = state.copyWith(
      clearInvestor: true,
      isSearchingUcc: false,
      showUcc: false,
      uccData: const [],
      clearUccSelection: true,
    );
  }


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


  Future<void> fetchUccData() async {
    final investor = state.selectedInvestor;
    if (investor == null) {
      SnackbarService.showError('Please select an investor first.');
      return;
    }

    final requestId = ++_activeUccRequestId;
    state = state.copyWith(
      isSearchingUcc: true,
      showUcc: false,
      uccData: const [],
      clearUccSelection: true,
    );

    try {
      final uccData = await OperationsApiService.fetchUccByPan(investor.pan);
      if (requestId != _activeUccRequestId) {
        return;
      }
      if (!mounted) return;

      state = state.copyWith(
        isSearchingUcc: false,
        showUcc: true,
        uccData: uccData,
        clearUccSelection: true,
      );

      if (uccData.isEmpty) {
        SnackbarService.showError('No UCC records found for this investor.');
        return;
      }

      unawaited(_hydrateKycStatuses(requestId: requestId, data: uccData));
    } catch (error) {
      if (requestId != _activeUccRequestId) {
        return;
      }
      if (!mounted) return;
      state = state.copyWith(
        isSearchingUcc: false,
        showUcc: false,
        uccData: const [],
        clearUccSelection: true,
      );
      SnackbarService.showError('Unable to fetch UCC data. Please try again.');
      debugPrint('[MfTransactionViewModel] fetchUccData failed: $error');
    }
  }

  Future<void> _hydrateKycStatuses({
    required int requestId,
    required List<UccModel> data,
  }) async {
    final pans = <String>{};
    for (final ucc in data) {
      if (ucc.primaryPan.isNotEmpty) {
        pans.add(ucc.primaryPan);
      }
      if (ucc.joint1Pan.isNotEmpty) {
        pans.add(ucc.joint1Pan);
      }
      if (ucc.joint2Pan.isNotEmpty) {
        pans.add(ucc.joint2Pan);
      }
    }

    if (pans.isEmpty) {
      return;
    }

    final kycStatusByPan = <String, UccKycStatus>{};
    await Future.wait(
      pans.map((pan) async {
        final status = await OperationsApiService.fetchKycStatus(pan);
        kycStatusByPan[pan] = status;
      }),
    );

    if (requestId != _activeUccRequestId) {
      return;
    }
    if (!mounted) return;

    final updatedData = data
        .map((item) => item.withKycStatuses(kycStatusByPan))
        .toList();
    state = state.copyWith(uccData: updatedData, showUcc: true);
  }

  void selectUcc(String id) => state = state.copyWith(selectedUccId: id);

  void deselectUcc() => state = state.copyWith(clearUccSelection: true);
}

final mfTransactionProvider =
    StateNotifierProvider<MfTransactionViewModel, MfTransactionState>(
      (ref) => MfTransactionViewModel(),
    );
