// lib/ViewModels/mfTransForm_viewModel.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../API/operations_apiService.dart';
import '../Services/snackBar_Service.dart';
import 'mfTransaction_viewModel.dart';

// ─────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────

enum FormTab { systematic, purchaseRedemption, switchTrans }

const List<String> _defaultFolioOptions = ['Select Folio', 'Create New Folio'];

// ─────────────────────────────────────────────
// Option Lists  (mirrors OptionListsSlice.js)
// ─────────────────────────────────────────────

class MfTransFormOptions {
  static const schemeOption = ['Growth', 'IDCW / Dividend'];

  static const purchaseUnitsAmount = ['Amount in next question'];

  static const redemptionUnitsAmount = [
    'Amount in next question',
    'Long Term Units',
    'Redeem All Units',
    'Units in next question',
    'Unlocked Units',
  ];

  static const switchUnitsAmount = [
    'Amount in next question',
    'Long Term Units',
    'Switch All Units',
    'Units in next question',
    'Unlocked Units',
  ];

  static const frequency = [
    'Daily',
    'Weekly',
    'Monthly',
    'Quarterly',
    'Annually',
  ];

  static const sipPauseMonths = [
    'Not Applicable',
    '1 Month',
    '2 Months',
    '3 Months',
    '4 Months',
    'Maximum Months',
  ];

  static const sysPaymentMode = [
    'Netbanking',
    'Mandate',
    'Cheque',
    'NEFT/RTGS',
    'Zero Balance',
    'UPI',
  ];

  static const purchPaymentMode = [
    'Netbanking',
    'Mandate',
    'Cheque',
    'NEFT/RTGS',
    'UPI',
  ];

  // static const sipStpSwpDate = [
  //   '1 to 10',
  //   '11 to 20',
  //   '21 to 30',
  //   'Call Client and take dates',
  //   'STP - SWP - at your comfort Level',
  // ];

  static const purchaseTraxType = ['Purchase', 'Redemption'];

  static const systematicTraxType = [
    'SIP',
    'STP',
    'Capital Appreciation STP',
    'SWP',
    'Capital Appreciation SWP',
  ];

  static const systematicTraxForWithPause = [
    'Registration',
    'Pause',
    'Cancellation',
  ];
  static const systematicTraxFor = ['Registration', 'Cancellation'];

  static const folioOptionsWithNew = _defaultFolioOptions;
}

// ─────────────────────────────────────────────
// Sub-states per tab (makes reset trivial)
// ─────────────────────────────────────────────

class PurchRedempTabState {
  final String traxType;
  final String unitAmountType;
  final String schemeOption;
  final String paymentMode;

  // Text field values (persisted in state for API submission)
  final String amcName;
  final String schemeName;
  final String folio;
  final List<String> folioOptions;
  final String amount;
  final String chequeNumber;

  const PurchRedempTabState({
    this.traxType = 'Purchase',
    this.unitAmountType = 'Amount in next question',
    this.schemeOption = 'Growth',
    this.paymentMode = 'Netbanking',
    this.amcName = '',
    this.schemeName = '',
    this.folio = 'Select Folio',
    this.folioOptions = _defaultFolioOptions,
    this.amount = '',
    this.chequeNumber = '',
  });

  PurchRedempTabState copyWith({
    String? traxType,
    String? unitAmountType,
    String? schemeOption,
    String? paymentMode,
    String? amcName,
    String? schemeName,
    String? folio,
    List<String>? folioOptions,
    String? amount,
    String? chequeNumber,
  }) => PurchRedempTabState(
    traxType: traxType ?? this.traxType,
    unitAmountType: unitAmountType ?? this.unitAmountType,
    schemeOption: schemeOption ?? this.schemeOption,
    paymentMode: paymentMode ?? this.paymentMode,
    amcName: amcName ?? this.amcName,
    schemeName: schemeName ?? this.schemeName,
    folio: folio ?? this.folio,
    folioOptions: folioOptions ?? this.folioOptions,
    amount: amount ?? this.amount,
    chequeNumber: chequeNumber ?? this.chequeNumber,
  );

  static const initial = PurchRedempTabState();
}

class SwitchTabState {
  final String unitAmountType;
  final String fromSchemeOption;
  final String toSchemeOption;

  final String amcName;
  final String fromScheme;
  final String toScheme;
  final String folio;
  final List<String> folioOptions;
  final String amount;

  const SwitchTabState({
    this.unitAmountType = 'Amount in next question',
    this.fromSchemeOption = 'Growth',
    this.toSchemeOption = 'Growth',
    this.amcName = '',
    this.fromScheme = '',
    this.toScheme = '',
    this.folio = 'Select Folio',
    this.folioOptions = _defaultFolioOptions,
    this.amount = '',
  });

  SwitchTabState copyWith({
    String? unitAmountType,
    String? fromSchemeOption,
    String? toSchemeOption,
    String? amcName,
    String? fromScheme,
    String? toScheme,
    String? folio,
    List<String>? folioOptions,
    String? amount,
  }) => SwitchTabState(
    unitAmountType: unitAmountType ?? this.unitAmountType,
    fromSchemeOption: fromSchemeOption ?? this.fromSchemeOption,
    toSchemeOption: toSchemeOption ?? this.toSchemeOption,
    amcName: amcName ?? this.amcName,
    fromScheme: fromScheme ?? this.fromScheme,
    toScheme: toScheme ?? this.toScheme,
    folio: folio ?? this.folio,
    folioOptions: folioOptions ?? this.folioOptions,
    amount: amount ?? this.amount,
  );

  static const initial = SwitchTabState();
}

class SystematicTabState {
  final String traxType;
  final String traxFor;
  final String schemeOption;
  final String frequency;
  final String date;
  final String paymentMode;
  final String sipPauseMonths;

  final String amcName;
  final String sourceScheme;
  final String targetScheme;
  final String folio;
  final List<String> folioOptions;
  final String amount;
  final String tenure;
  final String firstTransactionAmount;
  final String chequeNumber;

  const SystematicTabState({
    this.traxType = 'SIP',
    this.traxFor = 'Registration',
    this.schemeOption = 'Growth',
    this.frequency = 'Monthly',
    this.date = '',
    this.paymentMode = 'Netbanking',
    this.sipPauseMonths = 'Not Applicable',
    this.amcName = '',
    this.sourceScheme = '',
    this.targetScheme = '',
    this.folio = 'Select Folio',
    this.folioOptions = _defaultFolioOptions,
    this.amount = '',
    this.tenure = '',
    this.firstTransactionAmount = '',
    this.chequeNumber = '',
  });

  SystematicTabState copyWith({
    String? traxType,
    String? traxFor,
    String? schemeOption,
    String? frequency,
    String? date,
    String? paymentMode,
    String? sipPauseMonths,
    String? amcName,
    String? sourceScheme,
    String? targetScheme,
    String? folio,
    List<String>? folioOptions,
    String? amount,
    String? tenure,
    String? firstTransactionAmount,
    String? chequeNumber,
  }) => SystematicTabState(
    traxType: traxType ?? this.traxType,
    traxFor: traxFor ?? this.traxFor,
    schemeOption: schemeOption ?? this.schemeOption,
    frequency: frequency ?? this.frequency,
    date: date ?? this.date,
    paymentMode: paymentMode ?? this.paymentMode,
    sipPauseMonths: sipPauseMonths ?? this.sipPauseMonths,
    amcName: amcName ?? this.amcName,
    sourceScheme: sourceScheme ?? this.sourceScheme,
    targetScheme: targetScheme ?? this.targetScheme,
    folio: folio ?? this.folio,
    folioOptions: folioOptions ?? this.folioOptions,
    amount: amount ?? this.amount,
    tenure: tenure ?? this.tenure,
    firstTransactionAmount:
        firstTransactionAmount ?? this.firstTransactionAmount,
    chequeNumber: chequeNumber ?? this.chequeNumber,
  );

  static const initial = SystematicTabState();
}

// ─────────────────────────────────────────────
// Root Form State
// ─────────────────────────────────────────────

class MfTransFormState {
  final FormTab activeTab;
  final PurchRedempTabState purchRedemp;
  final SwitchTabState switchTab;
  final SystematicTabState systematic;
  final List<Map<String, dynamic>> savedTransactions;

  /// Incremented on tab switch → used as Widget key to force TextField rebuild/clear
  final int purchRedempResetKey;
  final int switchResetKey;
  final int systematicResetKey;

  const MfTransFormState({
    this.activeTab = FormTab.systematic,
    this.purchRedemp = PurchRedempTabState.initial,
    this.switchTab = SwitchTabState.initial,
    this.systematic = SystematicTabState.initial,
    this.savedTransactions = const [],
    this.purchRedempResetKey = 0,
    this.switchResetKey = 0,
    this.systematicResetKey = 0,
  });

  MfTransFormState copyWith({
    FormTab? activeTab,
    PurchRedempTabState? purchRedemp,
    SwitchTabState? switchTab,
    SystematicTabState? systematic,
    List<Map<String, dynamic>>? savedTransactions,
    int? purchRedempResetKey,
    int? switchResetKey,
    int? systematicResetKey,
  }) => MfTransFormState(
    activeTab: activeTab ?? this.activeTab,
    purchRedemp: purchRedemp ?? this.purchRedemp,
    switchTab: switchTab ?? this.switchTab,
    systematic: systematic ?? this.systematic,
    savedTransactions: savedTransactions ?? this.savedTransactions,
    purchRedempResetKey: purchRedempResetKey ?? this.purchRedempResetKey,
    switchResetKey: switchResetKey ?? this.switchResetKey,
    systematicResetKey: systematicResetKey ?? this.systematicResetKey,
  );
}

// ─────────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────────

class MfTransFormNotifier extends StateNotifier<MfTransFormState> {
  MfTransFormNotifier() : super(const MfTransFormState());

  Timer? _purchFolioDebounce;
  Timer? _switchFolioDebounce;
  Timer? _systematicFolioDebounce;
  int _purchFolioRequestId = 0;
  int _switchFolioRequestId = 0;
  int _systematicFolioRequestId = 0;

  Future<List<String>> searchAmcNames(String query) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    try {
      return await OperationsApiService.searchAmcNames(normalizedQuery);
    } catch (error) {
      debugPrint('[MfTransFormNotifier] AMC search failed: $error');
      return const [];
    }
  }

  Future<List<String>> searchSchemeNames({
    required String amc,
    required String query,
  }) async {
    final normalizedAmc = amc.trim();
    final normalizedQuery = query.trim();
    if (normalizedAmc.isEmpty || normalizedQuery.isEmpty) {
      return const [];
    }

    try {
      return await OperationsApiService.searchSchemeNames(
        amc: normalizedAmc,
        keywords: normalizedQuery,
      );
    } catch (error) {
      debugPrint('[MfTransFormNotifier] Scheme search failed: $error');
      return const [];
    }
  }

  List<String> _mergeFolioOptions(List<String> dynamicFolios) {
    final merged = <String>[..._defaultFolioOptions];
    for (final folio in dynamicFolios) {
      final normalized = folio.trim();
      if (normalized.isEmpty) {
        continue;
      }
      if (!merged.contains(normalized)) {
        merged.add(normalized);
      }
    }
    return merged;
  }

  Future<void> _fetchPurchRedempFolios({
    required String iWellCode,
    required String amcName,
    required int requestId,
  }) async {
    try {
      final folios = await OperationsApiService.fetchFolioOptions(
        iWellCode: iWellCode,
        amcName: amcName,
      );
      if (requestId != _purchFolioRequestId) {
        return;
      }
      final options = _mergeFolioOptions(folios);
      state = state.copyWith(
        purchRedemp: state.purchRedemp.copyWith(folioOptions: options),
      );
    } catch (error) {
      if (requestId != _purchFolioRequestId) {
        return;
      }
      debugPrint(
        '[MfTransFormNotifier] Purch/Redemp folio fetch failed: $error',
      );
      state = state.copyWith(
        purchRedemp: state.purchRedemp.copyWith(
          folioOptions: _defaultFolioOptions,
        ),
      );
    }
  }

  Future<void> _fetchSwitchFolios({
    required String iWellCode,
    required String amcName,
    required int requestId,
  }) async {
    try {
      final folios = await OperationsApiService.fetchFolioOptions(
        iWellCode: iWellCode,
        amcName: amcName,
      );
      if (requestId != _switchFolioRequestId) {
        return;
      }
      final options = _mergeFolioOptions(folios);
      state = state.copyWith(
        switchTab: state.switchTab.copyWith(folioOptions: options),
      );
    } catch (error) {
      if (requestId != _switchFolioRequestId) {
        return;
      }
      debugPrint('[MfTransFormNotifier] Switch folio fetch failed: $error');
      state = state.copyWith(
        switchTab: state.switchTab.copyWith(folioOptions: _defaultFolioOptions),
      );
    }
  }

  Future<void> _fetchSystematicFolios({
    required String iWellCode,
    required String amcName,
    required int requestId,
  }) async {
    try {
      final folios = await OperationsApiService.fetchFolioOptions(
        iWellCode: iWellCode,
        amcName: amcName,
      );
      if (requestId != _systematicFolioRequestId) {
        return;
      }
      final options = _mergeFolioOptions(folios);
      state = state.copyWith(
        systematic: state.systematic.copyWith(folioOptions: options),
      );
    } catch (error) {
      if (requestId != _systematicFolioRequestId) {
        return;
      }
      debugPrint('[MfTransFormNotifier] Systematic folio fetch failed: $error');
      state = state.copyWith(
        systematic: state.systematic.copyWith(
          folioOptions: _defaultFolioOptions,
        ),
      );
    }
  }

  Future<bool> submitAllTransactions(MfTransactionState step1State) async {
    // 1. Force save active form if it has data but wasn't pushed to cart
    bool isDirty = false;
    if (state.activeTab == FormTab.purchaseRedemption && state.purchRedemp.amount.isNotEmpty) isDirty = true;
    if (state.activeTab == FormTab.switchTrans && state.switchTab.amount.isNotEmpty) isDirty = true;
    if (state.activeTab == FormTab.systematic && state.systematic.amount.isNotEmpty) isDirty = true;

    if (isDirty) {
      saveCurrentTransactionAndReset();
    }

    if (state.savedTransactions.isEmpty) {
      SnackbarService.showError('Please complete at least one transaction before proceeding');
      return false;
    }

    try {
      // 2. Build commonData from Step 1 State
      final prefString = step1State.preference == TransPref.asap ? 'ASAP'
          : step1State.preference == TransPref.nextWorkingDay ? 'Next Working Day'
          : step1State.preference == TransPref.customDate ? step1State.selectedDate.toString()
          : step1State.preference == TransPref.customeDateTime ? step1State.selectedDate.toString() : "";

      final commonData = {
        'transactionPreference': prefString,
        'relationshipManager': step1State.selectedInvestor?.relationshipManager ?? '',
        'familyHead': step1State.selectedInvestor?.familyHead ?? '',
        'investorName': step1State.selectedInvestor?.name ?? '',
        'panNumber': step1State.selectedInvestor?.pan ?? '',
        'ucc': step1State.selectedUccId ?? '',
      };

      // 3. Map Form State into Backend Arrays
      final systematicData = <Map<String, dynamic>>[];
      final purchRedempData = <Map<String, dynamic>>[];
      final switchData = <Map<String, dynamic>>[];

      for (final tx in state.savedTransactions) {
        final title = tx['title'] as String;
        final data = tx['data'] as Map<String, dynamic>;

        if (title == 'Systematic Transaction') {
          systematicData.add({
            'systematicTraxType': data['transactionType'],
            'systematicTraxFor': data['transactionFor'],
            'systematicMfAmcName': data['amcName'],
            'systematicSchemeName': data['targetScheme'], // Target maps to schemeName
            'systematicSourceScheme': data['sourceScheme'],
            'systematicFolio': data['folio'],
            'sip_swp_stpAmount': data['amount'],
            'systematicPaymentMode': data['paymentMode'],
            'systematicSchemeOption': data['schemeOption'],
            'firstTransactionAmount': data['firstTransactionAmount'],
            'sip_stp_swpDate': data['date'],
            'sipPauseMonths': data['sipPauseMonths'],
            'tenureOfSip_swp_stp': data['tenure'],
            'systematicChequeNumber': data['chequeNumber'],
            'systematicFrequency': data['frequency'],
          });
        } else if (title == 'Purchase / Redemption') {
          final isAmount = data['unitAmountType'] == 'Amount in next question';
          final isUnitInput = data['unitAmountType'] == 'Units in next question';

          purchRedempData.add({
            'purch_RedempTraxType': data['transactionType'],
            'purch_redempMfAmcName': data['amcName'],
            'purch_redempSchemeName': data['schemeName'],
            'purch_redempFolio': data['folio'],
            'purch_redempTransactionAmount': isAmount ? num.tryParse(data['amount'].toString()) : null,
            'purch_redempTransactionUnits': isUnitInput ? num.tryParse(data['amount'].toString()) : null,
            'purch_redempPaymentMode': data['paymentMode'],
            'purch_redempSchemeOption': data['schemeOption'],
            'purch_redempTransactionUnits_Amount': data['unitAmountType'],
            'purchaseChequeNumber': data['chequeNumber'],
          });
        } else if (title == 'Switch Transaction') {
          final isAmount = data['unitAmountType'] == 'Amount in next question';
          final isUnitInput = data['unitAmountType'] == 'Units in next question';

          switchData.add({
            'switchMfAmcName': data['amcName'],
            'switchToScheme': data['toScheme'],
            'switchFromScheme': data['fromScheme'],
            'switchFolio': data['folio'],
            'switchTransactionUnits_Amount': data['unitAmountType'],
            'switchTransactionAmount': isAmount || isUnitInput ? num.tryParse(data['amount'].toString()) : null,
            'switchToSchemeOption': data['toSchemeOption'],
            'switchFromSchemeOption': data['fromSchemeOption'],
          });
        }
      }

      final payload = {
        'commonData': commonData,
        'systematicData': systematicData,
        'purchRedempData': purchRedempData,
        'switchData': switchData,
      };

      // 4. API Request
      await OperationsApiService.submitMfTransactions(payload);

      // 5. Success reset
      clearForm();
      return true;

    } catch (e) {
      SnackbarService.showError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  bool _isMissingValue(String? value, {Set<String> disallowed = const {}}) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      return true;
    }
    return disallowed.contains(normalized);
  }

  bool _validateField(
    String fieldLabel,
    String? value, {
    Set<String> disallowed = const {},
  }) {
    if (_isMissingValue(value, disallowed: disallowed)) {
      SnackbarService.showError('$fieldLabel is required');
      return false;
    }
    return true;
  }

  bool validateActiveFormForProceed() {
    switch (state.activeTab) {
      case FormTab.purchaseRedemption:
        final d = state.purchRedemp;
        if (!_validateField('Transaction Type', d.traxType)) return false;
        if (!_validateField('AMC Name', d.amcName)) return false;
        if (!_validateField('Scheme Name', d.schemeName)) return false;
        if (!_validateField('Scheme Option', d.schemeOption)) return false;
        if (!_validateField(
          'Folio',
          d.folio,
          // disallowed: const {'Select Folio'},
        )) {
          return false;
        }
        if (!_validateField('Transaction Units / Amount', d.unitAmountType)) {
          return false;
        }
        final needsAmount =
            d.unitAmountType == 'Amount in next question' ||
            d.unitAmountType == 'Units in next question';
        if (needsAmount && !_validateField('Amount', d.amount)) return false;
        if (d.traxType == 'Purchase' &&
            !_validateField('Payment Mode', d.paymentMode)) {
          return false;
        }
        if (d.traxType == 'Purchase' &&
            d.paymentMode == 'Cheque' &&
            !_validateField('Cheque Number', d.chequeNumber)) {
          return false;
        }
        return true;

      case FormTab.switchTrans:
        final d = state.switchTab;
        if (!_validateField('AMC Name', d.amcName)) return false;
        if (!_validateField('From Scheme', d.fromScheme)) return false;
        if (!_validateField('From Scheme Option', d.fromSchemeOption)) {
          return false;
        }
        if (!_validateField('To Scheme', d.toScheme)) return false;
        if (!_validateField('To Scheme Option', d.toSchemeOption)) {
          return false;
        }
        if (!_validateField(
          'Folio',
          d.folio,
          disallowed: const {'Select Folio'},
        )) {
          return false;
        }
        if (!_validateField('Transaction Units / Amount', d.unitAmountType)) {
          return false;
        }
        final needsAmount =
            d.unitAmountType == 'Amount in next question' ||
            d.unitAmountType == 'Units in next question';
        if (needsAmount && !_validateField('Amount', d.amount)) return false;
        return true;

      case FormTab.systematic:
        final d = state.systematic;
        final isSIP = d.traxType == 'SIP';
        final isSTP = d.traxType == 'STP';
        final isCapSTP = d.traxType == 'Capital Appreciation STP';
        final isSWP = d.traxType == 'SWP';
        final isCapSWP = d.traxType == 'Capital Appreciation SWP';

        final showFrequencyAndDate =
            [
              'SIP',
              'STP',
              'SWP',
              'Capital Appreciation STP',
              'Capital Appreciation SWP',
            ].contains(d.traxType) &&
            d.traxFor == 'Registration';

        final showSourceScheme = isSTP || isCapSTP || isSWP || isCapSWP;
        final showTargetScheme = isSIP || isSTP || isCapSTP;

        final showTenure =
            (isSIP && ['Registration', 'Pause'].contains(d.traxFor)) ||
            ([
                  'SWP',
                  'Capital Appreciation SWP',
                  'STP',
                  'Capital Appreciation STP',
                ].contains(d.traxType) &&
                d.traxFor == 'Registration');

        final showFirstAmount =
            (isSIP && d.traxFor == 'Registration') ||
            (['SWP', 'Capital Appreciation SWP'].contains(d.traxType) &&
                d.traxFor == 'Registration') ||
            (['STP', 'Capital Appreciation STP'].contains(d.traxType) &&
                d.traxFor == 'Cancellation');

        if (!_validateField('Transaction Type', d.traxType)) return false;
        if (!_validateField('Transaction For', d.traxFor)) return false;
        if (!_validateField('AMC Name', d.amcName)) return false;
        if (showTargetScheme &&
            !_validateField('Target Scheme', d.targetScheme)) {
          return false;
        }
        if (!_validateField('Scheme Option', d.schemeOption)) return false;
        if (!_validateField(
          'Folio',
          d.folio,
          disallowed: const {'Select Folio'},
        )) {
          return false;
        }
        if (!_validateField('Amount', d.amount)) return false;
        if (showTenure && !_validateField('Tenure (Months)', d.tenure)) {
          return false;
        }
        if (showFrequencyAndDate && !_validateField('Frequency', d.frequency)) {
          return false;
        }
        if (showFrequencyAndDate &&
            !_validateField('SIP / STP / SWP Date', d.date)) {
          return false;
        }
        if (showSourceScheme &&
            !_validateField('Source Scheme', d.sourceScheme)) {
          return false;
        }
        if (d.traxFor == 'Pause' &&
            isSIP &&
            !_validateField('SIP Pause Months', d.sipPauseMonths)) {
          return false;
        }
        if (showFirstAmount &&
            !_validateField(
              'First Transaction Amount',
              d.firstTransactionAmount,
            )) {
          return false;
        }
        if (isSIP &&
            d.traxFor == 'Registration' &&
            !_validateField('First Installment Payment Mode', d.paymentMode)) {
          return false;
        }
        if (isSIP &&
            d.traxFor == 'Registration' &&
            d.paymentMode == 'Cheque' &&
            !_validateField('Cheque Number', d.chequeNumber)) {
          return false;
        }
        return true;
    }
  }

  // ── Tab ───────────────────────────────────────────────────────────────────

  void setTab(FormTab tab) {
    if (tab == state.activeTab) return;

    // Reset the *target* tab's data and increment its reset key
    // so all TextFields within it rebuild as empty.
    switch (tab) {
      case FormTab.purchaseRedemption:
        state = state.copyWith(
          activeTab: tab,
          purchRedemp: PurchRedempTabState.initial,
          purchRedempResetKey: state.purchRedempResetKey + 1,
        );
        break;
      case FormTab.switchTrans:
        state = state.copyWith(
          activeTab: tab,
          switchTab: SwitchTabState.initial,
          switchResetKey: state.switchResetKey + 1,
        );
        break;
      case FormTab.systematic:
        state = state.copyWith(
          activeTab: tab,
          systematic: SystematicTabState.initial,
          systematicResetKey: state.systematicResetKey + 1,
        );
        break;
    }
  }

  // ── Purchase / Redemption ─────────────────────────────────────────────────

  void updatePurchRedemp(String key, String val) {
    final current = state.purchRedemp;
    switch (key) {
      case 'traxType':
        state = state.copyWith(
          purchRedemp: current.copyWith(
            traxType: val,
            unitAmountType: 'Amount in next question',
          ),
        );
        break;
      case 'unitAmountType':
        state = state.copyWith(
          purchRedemp: current.copyWith(unitAmountType: val),
        );
        break;
      case 'schemeOption':
        state = state.copyWith(
          purchRedemp: current.copyWith(schemeOption: val),
        );
        break;
      case 'paymentMode':
        state = state.copyWith(purchRedemp: current.copyWith(paymentMode: val));
        break;
      case 'amcName':
        state = state.copyWith(purchRedemp: current.copyWith(amcName: val));
        break;
      case 'schemeName':
        state = state.copyWith(purchRedemp: current.copyWith(schemeName: val));
        break;
      case 'folio':
        state = state.copyWith(purchRedemp: current.copyWith(folio: val));
        break;
      case 'amount':
        state = state.copyWith(purchRedemp: current.copyWith(amount: val));
        break;
      case 'chequeNumber':
        state = state.copyWith(
          purchRedemp: current.copyWith(chequeNumber: val),
        );
        break;
    }
  }

  void updatePurchRedempAmc(String val, {String? iWellCode}) {
    final current = state.purchRedemp;
    final normalizedAmc = val.trim();
    state = state.copyWith(
      purchRedemp: current.copyWith(
        amcName: normalizedAmc,
        schemeName: '',
        folio: 'Select Folio',
        folioOptions: _defaultFolioOptions,
      ),
    );

    final normalizedIwell = iWellCode?.trim() ?? '';
    if (normalizedAmc.isEmpty || normalizedIwell.isEmpty) {
      _purchFolioDebounce?.cancel();
      _purchFolioRequestId++;
      return;
    }

    _purchFolioDebounce?.cancel();
    _purchFolioDebounce = Timer(const Duration(milliseconds: 260), () {
      final requestId = ++_purchFolioRequestId;
      _fetchPurchRedempFolios(
        iWellCode: normalizedIwell,
        amcName: normalizedAmc,
        requestId: requestId,
      );
    });
  }

  // ── Switch ────────────────────────────────────────────────────────────────

  void updateSwitch(String key, String val) {
    final current = state.switchTab;
    switch (key) {
      case 'unitAmountType':
        state = state.copyWith(
          switchTab: current.copyWith(unitAmountType: val),
        );
        break;
      case 'fromSchemeOption':
        state = state.copyWith(
          switchTab: current.copyWith(fromSchemeOption: val),
        );
        break;
      case 'toSchemeOption':
        state = state.copyWith(
          switchTab: current.copyWith(toSchemeOption: val),
        );
        break;
      case 'amcName':
        state = state.copyWith(switchTab: current.copyWith(amcName: val));
        break;
      case 'fromScheme':
        state = state.copyWith(switchTab: current.copyWith(fromScheme: val));
        break;
      case 'toScheme':
        state = state.copyWith(switchTab: current.copyWith(toScheme: val));
        break;
      case 'folio':
        state = state.copyWith(switchTab: current.copyWith(folio: val));
        break;
      case 'amount':
        state = state.copyWith(switchTab: current.copyWith(amount: val));
        break;
    }
  }

  void updateSwitchAmc(String val, {String? iWellCode}) {
    final current = state.switchTab;
    final normalizedAmc = val.trim();
    state = state.copyWith(
      switchTab: current.copyWith(
        amcName: normalizedAmc,
        toScheme: '',
        folio: 'Select Folio',
        folioOptions: _defaultFolioOptions,
      ),
    );

    final normalizedIwell = iWellCode?.trim() ?? '';
    if (normalizedAmc.isEmpty || normalizedIwell.isEmpty) {
      _switchFolioDebounce?.cancel();
      _switchFolioRequestId++;
      return;
    }

    _switchFolioDebounce?.cancel();
    _switchFolioDebounce = Timer(const Duration(milliseconds: 260), () {
      final requestId = ++_switchFolioRequestId;
      _fetchSwitchFolios(
        iWellCode: normalizedIwell,
        amcName: normalizedAmc,
        requestId: requestId,
      );
    });
  }

  // ── Systematic ────────────────────────────────────────────────────────────

  void updateSystematic(String key, String val) {
    final current = state.systematic;
    switch (key) {
      case 'traxType':
        final newFor = (val != 'SIP' && current.traxFor == 'Pause')
            ? 'Registration'
            : current.traxFor;
        state = state.copyWith(
          systematic: current.copyWith(traxType: val, traxFor: newFor),
        );
        break;
      case 'traxFor':
        state = state.copyWith(systematic: current.copyWith(traxFor: val));
        break;
      case 'schemeOption':
        state = state.copyWith(systematic: current.copyWith(schemeOption: val));
        break;
      case 'frequency':
        state = state.copyWith(systematic: current.copyWith(frequency: val));
        break;
      case 'date':
        state = state.copyWith(systematic: current.copyWith(date: val));
        break;
      case 'paymentMode':
        state = state.copyWith(systematic: current.copyWith(paymentMode: val));
        break;
      case 'sipPauseMonths':
        state = state.copyWith(
          systematic: current.copyWith(sipPauseMonths: val),
        );
        break;
      case 'amcName':
        state = state.copyWith(systematic: current.copyWith(amcName: val));
        break;
      case 'sourceScheme':
        state = state.copyWith(systematic: current.copyWith(sourceScheme: val));
        break;
      case 'targetScheme':
        state = state.copyWith(systematic: current.copyWith(targetScheme: val));
        break;
      case 'folio':
        state = state.copyWith(systematic: current.copyWith(folio: val));
        break;
      case 'amount':
        state = state.copyWith(systematic: current.copyWith(amount: val));
        break;
      case 'tenure':
        state = state.copyWith(systematic: current.copyWith(tenure: val));
        break;
      case 'firstTransactionAmount':
        state = state.copyWith(
          systematic: current.copyWith(firstTransactionAmount: val),
        );
        break;
      case 'chequeNumber':
        state = state.copyWith(systematic: current.copyWith(chequeNumber: val));
        break;
    }
  }

  void updateSystematicAmc(String val, {String? iWellCode}) {
    final current = state.systematic;
    final normalizedAmc = val.trim();
    state = state.copyWith(
      systematic: current.copyWith(
        amcName: normalizedAmc,
        targetScheme: '',
        folio: 'Select Folio',
        folioOptions: _defaultFolioOptions,
      ),
    );

    final normalizedIwell = iWellCode?.trim() ?? '';
    if (normalizedAmc.isEmpty || normalizedIwell.isEmpty) {
      _systematicFolioDebounce?.cancel();
      _systematicFolioRequestId++;
      return;
    }

    _systematicFolioDebounce?.cancel();
    _systematicFolioDebounce = Timer(const Duration(milliseconds: 260), () {
      final requestId = ++_systematicFolioRequestId;
      _fetchSystematicFolios(
        iWellCode: normalizedIwell,
        amcName: normalizedAmc,
        requestId: requestId,
      );
    });
  }

  //multiple trax handler
  void saveCurrentTransactionAndReset() {
    bool isDirty = false;
    if (state.activeTab == FormTab.purchaseRedemption &&
        state.purchRedemp.amount.isNotEmpty) {
      isDirty = true;
    }
    if (state.activeTab == FormTab.switchTrans &&
        state.switchTab.amount.isNotEmpty) {
      isDirty = true;
    }
    if (state.activeTab == FormTab.systematic &&
        state.systematic.amount.isNotEmpty) {
      isDirty = true;
    }

    List<Map<String, dynamic>> newSaved = List.from(state.savedTransactions);

    if (isDirty) {
      String formTitle = '';
      Map<String, dynamic> payload = {};

      switch (state.activeTab) {
        case FormTab.purchaseRedemption:
          formTitle = 'Purchase / Redemption';
          payload = buildPurchRedempPayload();
          break;
        case FormTab.switchTrans:
          formTitle = 'Switch Transaction';
          payload = buildSwitchPayload();
          break;
        case FormTab.systematic:
          formTitle = 'Systematic Transaction';
          payload = buildSystematicPayload();
          break;
      }

      final newTx = {'title': formTitle, 'data': payload};
      newSaved.add(newTx);
    }

    // Stash the active form into the array (if dirty) and reset all form inputs
    state = state.copyWith(
      savedTransactions: newSaved,
      purchRedemp: PurchRedempTabState.initial,
      switchTab: SwitchTabState.initial,
      systematic: SystematicTabState.initial,
      purchRedempResetKey: state.purchRedempResetKey + 1,
      switchResetKey: state.switchResetKey + 1,
      systematicResetKey: state.systematicResetKey + 1,
    );
  }

  // Load a transaction back to the editor, placing the current active form into the stash
  void editTransaction(int index) {
    if (index >= state.savedTransactions.length) return;

    // Get target tx before doing anything
    final txToEdit = state.savedTransactions[index];

    // Only stash the current active form if the user actually typed something
    bool isDirty = false;
    if (state.activeTab == FormTab.purchaseRedemption &&
        state.purchRedemp.amount.isNotEmpty) {
      isDirty = true;
    }
    if (state.activeTab == FormTab.switchTrans &&
        state.switchTab.amount.isNotEmpty) {
      isDirty = true;
    }
    if (state.activeTab == FormTab.systematic &&
        state.systematic.amount.isNotEmpty) {
      isDirty = true;
    }

    if (isDirty) {
      saveCurrentTransactionAndReset();
    }

    // Refresh the list from state (since saveCurrentTransactionAndReset modifies it)
    final newList = List<Map<String, dynamic>>.from(state.savedTransactions);

    // Remove the target transaction from the cart
    newList.removeAt(index);

    final title = txToEdit['title'] as String;
    final data = txToEdit['data'] as Map<String, dynamic>;

    if (title == 'Purchase / Redemption') {
      state = state.copyWith(
        activeTab: FormTab.purchaseRedemption,
        savedTransactions: newList,
        purchRedemp: PurchRedempTabState(
          traxType: data['transactionType'] ?? 'Purchase',
          unitAmountType: data['unitAmountType'] ?? 'Amount in next question',
          schemeOption: data['schemeOption'] ?? 'Growth',
          paymentMode: data['paymentMode'] ?? 'Netbanking',
          amcName: data['amcName'] ?? '',
          schemeName: data['schemeName'] ?? '',
          folio: data['folio'] ?? 'Select Folio',
          amount: data['amount'] ?? '',
          chequeNumber: data['chequeNumber'] ?? '',
        ),
        purchRedempResetKey: state.purchRedempResetKey + 1,
      );
    } else if (title == 'Switch Transaction') {
      state = state.copyWith(
        activeTab: FormTab.switchTrans,
        savedTransactions: newList,
        switchTab: SwitchTabState(
          unitAmountType: data['unitAmountType'] ?? 'Amount in next question',
          fromSchemeOption: data['fromSchemeOption'] ?? 'Growth',
          toSchemeOption: data['toSchemeOption'] ?? 'Growth',
          amcName: data['amcName'] ?? '',
          fromScheme: data['fromScheme'] ?? '',
          toScheme: data['toScheme'] ?? '',
          folio: data['folio'] ?? 'Select Folio',
          amount: data['amount'] ?? '',
        ),
        switchResetKey: state.switchResetKey + 1,
      );
    } else if (title == 'Systematic Transaction') {
      state = state.copyWith(
        activeTab: FormTab.systematic,
        savedTransactions: newList,
        systematic: SystematicTabState(
          traxType: data['transactionType'] ?? 'SIP',
          traxFor: data['transactionFor'] ?? 'Registration',
          schemeOption: data['schemeOption'] ?? 'Growth',
          frequency: data['frequency'] ?? 'Monthly',
          date: data['date'] ?? '',
          paymentMode: data['paymentMode'] ?? 'Netbanking',
          sipPauseMonths: data['sipPauseMonths'] ?? 'Not Applicable',
          amcName: data['amcName'] ?? '',
          sourceScheme: data['sourceScheme'] ?? '',
          targetScheme: data['targetScheme'] ?? '',
          folio: data['folio'] ?? 'Select Folio',
          amount: data['amount'] ?? '',
          tenure: data['tenure'] ?? '',
          firstTransactionAmount: data['firstTransactionAmount'] ?? '',
          chequeNumber: data['chequeNumber'] ?? '',
        ),
        systematicResetKey: state.systematicResetKey + 1,
      );
    }
  }

  // Remove a transaction from the stashed list
  void deleteTransaction(int index) {
    if (index < 0 || index >= state.savedTransactions.length) return;

    final newList = List<Map<String, dynamic>>.from(state.savedTransactions);
    newList.removeAt(index);

    state = state.copyWith(savedTransactions: newList);
  }

  void clearForm() {
    state = const MfTransFormState();
  }

  // ── API Payload Builder ───────────────────────────────────────────────────
  // TODO: call these from a repository when Step 3 submits

  Map<String, dynamic> buildPurchRedempPayload() {
    final d = state.purchRedemp;
    return {
      'transactionType': d.traxType,
      'unitAmountType': d.unitAmountType,
      'schemeOption': d.schemeOption,
      'amcName': d.amcName,
      'schemeName': d.schemeName,
      'folio': d.folio,
      'amount': d.amount,
      if (d.traxType == 'Purchase') 'paymentMode': d.paymentMode,
      if (d.paymentMode == 'Cheque') 'chequeNumber': d.chequeNumber,
    };
  }

  Map<String, dynamic> buildSwitchPayload() {
    final d = state.switchTab;
    return {
      'unitAmountType': d.unitAmountType,
      'amcName': d.amcName,
      'fromScheme': d.fromScheme,
      'fromSchemeOption': d.fromSchemeOption,
      'toScheme': d.toScheme,
      'toSchemeOption': d.toSchemeOption,
      'folio': d.folio,
      'amount': d.amount,
    };
  }

  Map<String, dynamic> buildSystematicPayload() {
    final d = state.systematic;
    return {
      'transactionType': d.traxType,
      'transactionFor': d.traxFor,
      'schemeOption': d.schemeOption,
      'frequency': d.frequency,
      'date': d.date,
      'amcName': d.amcName,
      'sourceScheme': d.sourceScheme,
      'targetScheme': d.targetScheme,
      'folio': d.folio,
      'amount': d.amount,
      'tenure': d.tenure,
      'firstTransactionAmount': d.firstTransactionAmount,
      if (d.traxType == 'SIP' && d.traxFor == 'Registration')
        'paymentMode': d.paymentMode,
      if (d.traxFor == 'Pause') 'sipPauseMonths': d.sipPauseMonths,
      if (d.paymentMode == 'Cheque') 'chequeNumber': d.chequeNumber,
    };
  }

  @override
  void dispose() {
    _purchFolioDebounce?.cancel();
    _switchFolioDebounce?.cancel();
    _systematicFolioDebounce?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────
// Provider  (NOT autoDispose — persists across step navigation and screen pops)
// ─────────────────────────────────────────────

final mfTransFormProvider =
    StateNotifierProvider<MfTransFormNotifier, MfTransFormState>(
      (ref) => MfTransFormNotifier(),
    );
