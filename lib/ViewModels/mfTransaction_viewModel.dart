import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../Models/mftrans_models.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../Models/mftrans_models.dart';

enum TransPref { asap, nextWorkingDay, custom }

class MfTransactionState {
  final TransPref preference;
  final bool isLoadingFields;
  final bool isSearchingUcc;
  final bool showUcc;
  final DateTime? selectedDate;
  final InvestorModel? selectedInvestor;
  final String panNumber;
  final String familyHead;
  final List<UccModel> uccData;
  final String? selectedUccId;

  MfTransactionState({
    this.preference = TransPref.asap,
    this.isLoadingFields = false,
    this.isSearchingUcc = false,
    this.showUcc = false,
    this.selectedDate,
    this.selectedInvestor,
    this.panNumber = '',
    this.familyHead = '',
    this.uccData = const [],
    this.selectedUccId,
  });

  MfTransactionState copyWith({
    TransPref? preference,
    bool? isLoadingFields,
    bool? isSearchingUcc,
    bool? showUcc,
    DateTime? selectedDate,
    InvestorModel? selectedInvestor,
    String? panNumber,
    String? familyHead,
    List<UccModel>? uccData,
    String? selectedUccId,
    bool clearUccSelection = false,
  }) {
    return MfTransactionState(
      preference: preference ?? this.preference,
      isLoadingFields: isLoadingFields ?? this.isLoadingFields,
      isSearchingUcc: isSearchingUcc ?? this.isSearchingUcc,
      showUcc: showUcc ?? this.showUcc,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedInvestor: selectedInvestor ?? this.selectedInvestor,
      panNumber: panNumber ?? this.panNumber,
      familyHead: familyHead ?? this.familyHead,
      uccData: uccData ?? this.uccData,
      selectedUccId: clearUccSelection ? null : (selectedUccId ?? this.selectedUccId),
    );
  }
}

class MfTransactionViewModel extends StateNotifier<MfTransactionState> {
  MfTransactionViewModel() : super(MfTransactionState(
    selectedDate: _getDefaultDateTime(),
  ));

  final List<InvestorModel> _mockInvestors = [
    InvestorModel(name: "ATUL BHAMBRI", pan: "ABCDE1234F", familyHead: "ATUL BHAMBRI"),
    InvestorModel(name: "JOHN DOE", pan: "QWERT9876X", familyHead: "JOHN DOE"),
    InvestorModel(name: "A R COMPUTERS", pan: "ZXCVB5432M", familyHead: "ALICE R"),
  ];

  static DateTime _getDefaultDateTime() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 10, 0);
  }

  // jumps to monday if tomorrow is sunday
  DateTime _getNextWorkingDay() {
    DateTime next = DateTime.now().add(const Duration(days: 1));
    if (next.weekday == DateTime.sunday) {
      next = next.add(const Duration(days: 1));
    }
    return DateTime(next.year, next.month, next.day, 10, 0);
  }

  void setPreference(TransPref pref) {
    DateTime? updatedDate = state.selectedDate;

    // auto-set the calculated date when user taps Next Working Day
    if (pref == TransPref.nextWorkingDay) {
      updatedDate = _getNextWorkingDay();
    }

    state = state.copyWith(preference: pref, selectedDate: updatedDate);
  }

  void setDate(DateTime date) => state = state.copyWith(selectedDate: date);

  Future<List<InvestorModel>> searchByName(String query) async {
    if (query.isEmpty) return [];
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockInvestors.where((inv) => inv.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  Future<List<InvestorModel>> searchByPan(String query) async {
    if (query.isEmpty) return [];
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockInvestors.where((inv) => inv.pan.toLowerCase().contains(query.toLowerCase())).toList();
  }

  Future<List<InvestorModel>> searchByFamilyHead(String query) async {
    if (query.isEmpty) return [];
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockInvestors.where((inv) => inv.familyHead.toLowerCase().contains(query.toLowerCase())).toList();
  }

  void selectInvestor(InvestorModel investor) {
    state = state.copyWith(selectedInvestor: investor, panNumber: investor.pan, familyHead: investor.familyHead);
  }

  Future<void> fetchUccData() async {
    state = state.copyWith(isSearchingUcc: true, showUcc: false, clearUccSelection: true);
    await Future.delayed(const Duration(seconds: 1));

    final mockData = [
      UccModel(name: "Atul Bhambri", id: "AFBPB5026P", bseStatus: "Active", bank: "BANK/7656", nominee: "Yes", isValidated: true),
      UccModel(name: "A R Computers", id: "AFBPB5PROP", bseStatus: "Inactive", bank: "SOUTH/2631", nominee: "No", isValidated: true),
    ];

    state = state.copyWith(isSearchingUcc: false, showUcc: true, uccData: mockData);
  }

  void selectUcc(String id) => state = state.copyWith(selectedUccId: id);
  void deselectUcc() => state = state.copyWith(clearUccSelection: true);
}

final mfTransactionProvider = StateNotifierProvider<MfTransactionViewModel, MfTransactionState>((ref) {
  return MfTransactionViewModel();
});