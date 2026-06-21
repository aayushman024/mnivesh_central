// lib/Models/mftrans_models.dart

enum UccKycStatus { checking, validated, registered, rejected }

class UccBankDetail {
  final int index;
  final String bankName;
  final String accountNumber;
  final String status;

  const UccBankDetail({
    required this.index,
    required this.bankName,
    required this.accountNumber,
    required this.status,
  });

  String get shortLabel {
    final shortBank = bankName.split(' ').first;
    final lastFour = accountNumber.length > 4
        ? accountNumber.substring(accountNumber.length - 4)
        : accountNumber;
    return '$shortBank / $lastFour';
  }

  String get longLabel => 'Bank $index: $bankName / $accountNumber';

  bool get isValid => status.toUpperCase() == 'VALID';
}

class InvestorModel {
  final String name;
  final String pan;
  final String familyHead;
  final String iWellCode;
  final String relationshipManager;

  const InvestorModel({
    required this.name,
    required this.pan,
    required this.familyHead,
    this.iWellCode = '',
    this.relationshipManager = '',
  });

  factory InvestorModel.fromJson(Map<String, dynamic> json) {
    return InvestorModel(
      name: _readString(json['NAME']) ?? '',
      pan: (_readString(json['PAN']) ?? '').toUpperCase(),
      familyHead: _readString(json['FAMILY HEAD']) ?? '',
      iWellCode: _readString(json['IWELL CODE']) ?? '',
      relationshipManager: _readString(json['RELATIONSHIP  MANAGER']) ?? '',
    );
  }
}

class UccModel {
  static const Map<String, String> _holdingMap = {
    'SINGLE': 'SI',
    'JOINT': 'JO',
    'ANYONE OR SURVIVOR': 'AS',
  };

  static const Map<String, String> _taxStatusMap = {
    'INDIVIDUAL': 'IND',
    'ON BEHALF OF MINOR': 'OBM',
    'HUF': 'HUF',
    'COMPANY': 'PVT',
    'PRIVATE LIMITED COMPANY': 'PVT',
    'AOP/BOI': 'AOP',
    'PARTNERSHIP FIRM': 'LLP',
    'LLP': 'LLP',
    'BODY CORPORATE': 'BC',
    'TRUST': 'TRUST',
    'SOCIETY': 'SOC',
    'OTHERS': 'OTH',
    'NRI-OTHERS': 'NRI-O',
    'BANKS / FINANCIAL INSTITUTIONS': 'BFI',
    'SOLE PROPRIETORSHIP': 'SP',
    'BANKS': 'BNK',
    'ASSOCIATION OF PERSONS': 'AOP',
    'NRI - REPATRIABLE (NRE)': 'NRE',
    'OVERSEAS CORPORATE BODY': 'OCB',
    'FOREIGN INSTITUTIONAL INVESTOR': 'FII',
    'NRI - NRO (NON REPATRIATION)': 'NRO',
    'NRI - REPATRIABLE (NRO)': 'NRO',
    'OVERSEAS CORPORATE BODY-OTHERS': 'OCB-O',
    'NRI - MINOR (NRE)': 'NRI-M',
  };

  final String id;
  final String name;
  final String primaryPan;
  final String joint1Name;
  final String joint2Name;
  final String joint1Pan;
  final String joint2Pan;
  final String bseStatus;
  final String bank;
  final String nominee;
  final String taxHolding;
  final String taxStatusFull;
  final String holdingNatureFull;
  final bool primaryPanAadhaarValid;
  final bool anyValidBank;
  final bool hasNominee;
  final List<UccBankDetail> banks;
  final List<String> nomineeNames;
  final UccKycStatus primaryKycStatus;
  final UccKycStatus joint1KycStatus;
  final UccKycStatus joint2KycStatus;
  final UccKycStatus kycStatus;

  const UccModel({
    required this.id,
    required this.name,
    required this.primaryPan,
    required this.joint1Name,
    required this.joint2Name,
    required this.joint1Pan,
    required this.joint2Pan,
    required this.bseStatus,
    required this.bank,
    required this.nominee,
    required this.taxHolding,
    required this.taxStatusFull,
    required this.holdingNatureFull,
    required this.primaryPanAadhaarValid,
    required this.anyValidBank,
    required this.hasNominee,
    required this.banks,
    required this.nomineeNames,
    required this.primaryKycStatus,
    required this.joint1KycStatus,
    required this.joint2KycStatus,
    required this.kycStatus,
  });

  factory UccModel.fromBackendJson(
    Map<String, dynamic> json, {
    Map<String, UccKycStatus> kycStatusByPan = const {},
  }) {
    final id = _readString(json['_id']) ?? '';
    final name = _readString(json['Primary_Holder_First_Name']) ?? '--';
    final primaryPan = (_readString(json['Primary_Holder_PAN']) ?? '')
        .toUpperCase();
    final secondPan = (_readString(json['Second_Holder_PAN']) ?? '')
        .toUpperCase();
    final thirdPan = (_readString(json['Third_Holder_PAN']) ?? '')
        .toUpperCase();
    final tax = _readString(json['Tax_Status']) ?? '';
    final holding = _readString(json['Holding_Nature']) ?? '';
    final banks = _extractBanks(json);
    final nomineeNames = _extractNomineeNames(json);
    final primaryKycStatus = _statusForPan(primaryPan, kycStatusByPan);
    final joint1KycStatus = _statusForPan(secondPan, kycStatusByPan);
    final joint2KycStatus = _statusForPan(thirdPan, kycStatusByPan);
    final hasNominee =
        (_readString(json['Nomination_Flag']) ?? '').toUpperCase() == 'Y';
    final primaryPanAadhaarValid =
        (_readString(json['Primary_Holder_PAN_Aadhaar_Status']) ?? '')
            .toUpperCase() ==
        'VALID';
    final anyValidBank = _hasAnyValidBankStatus(json);

    return UccModel(
      id: id,
      name: name,
      primaryPan: primaryPan,
      joint1Name: _readString(json['Second_Holder_First_Name']) ?? '--',
      joint2Name: _readString(json['Third_Holder_First_Name']) ?? '--',
      joint1Pan: secondPan,
      joint2Pan: thirdPan,
      bseStatus: _determineBseStatus(json),
      bank: banks.isEmpty ? 'N/A' : banks.first.shortLabel,
      nominee: hasNominee ? 'Yes' : 'No',
      taxHolding:
          '${_taxStatusMap[tax.toUpperCase()] ?? (tax.isEmpty ? 'N/A' : tax)} / '
          '${_holdingMap[holding.toUpperCase()] ?? (holding.isEmpty ? 'N/A' : holding)}',
      taxStatusFull: tax.isEmpty ? 'N/A' : tax,
      holdingNatureFull: holding.isEmpty ? 'N/A' : holding,
      primaryPanAadhaarValid: primaryPanAadhaarValid,
      anyValidBank: anyValidBank,
      hasNominee: hasNominee,
      banks: banks,
      nomineeNames: nomineeNames,
      primaryKycStatus: primaryKycStatus,
      joint1KycStatus: joint1KycStatus,
      joint2KycStatus: joint2KycStatus,
      kycStatus: _resolveOverallKycStatus(
        statuses: [primaryKycStatus, joint1KycStatus, joint2KycStatus],
        hasHolderFlags: [true, secondPan.isNotEmpty, thirdPan.isNotEmpty],
      ),
    );
  }

  UccModel withKycStatuses(Map<String, UccKycStatus> kycStatusByPan) {
    return UccModel(
      id: id,
      name: name,
      primaryPan: primaryPan,
      joint1Name: joint1Name,
      joint2Name: joint2Name,
      joint1Pan: joint1Pan,
      joint2Pan: joint2Pan,
      bseStatus: bseStatus,
      bank: bank,
      nominee: nominee,
      taxHolding: taxHolding,
      taxStatusFull: taxStatusFull,
      holdingNatureFull: holdingNatureFull,
      primaryPanAadhaarValid: primaryPanAadhaarValid,
      anyValidBank: anyValidBank,
      hasNominee: hasNominee,
      banks: banks,
      nomineeNames: nomineeNames,
      primaryKycStatus: _statusForPan(primaryPan, kycStatusByPan),
      joint1KycStatus: _statusForPan(joint1Pan, kycStatusByPan),
      joint2KycStatus: _statusForPan(joint2Pan, kycStatusByPan),
      kycStatus: _resolveOverallKycStatus(
        statuses: [
          _statusForPan(primaryPan, kycStatusByPan),
          _statusForPan(joint1Pan, kycStatusByPan),
          _statusForPan(joint2Pan, kycStatusByPan),
        ],
        hasHolderFlags: [true, joint1Pan.isNotEmpty, joint2Pan.isNotEmpty],
      ),
    );
  }

  String get kycLabel {
    switch (kycStatus) {
      case UccKycStatus.validated:
        return 'Validated';
      case UccKycStatus.registered:
        return 'Registered';
      case UccKycStatus.rejected:
        return 'Rejected';
      case UccKycStatus.checking:
        return 'Checking...';
    }
  }

  bool get isValidated => kycStatus == UccKycStatus.validated;

  static UccKycStatus parseKycStatus(dynamic responseData) {
    if (responseData is! Map) {
      return UccKycStatus.checking;
    }

    final data = Map<String, dynamic>.from(responseData);
    final normalized = (_readString(data['Status']) ?? '').toUpperCase();
    if (normalized.contains('VALIDATED')) {
      return UccKycStatus.validated;
    }
    if (normalized.contains('REGISTERED')) {
      return UccKycStatus.registered;
    }
    if (normalized.contains('REJECTED')) {
      return UccKycStatus.rejected;
    }
    return UccKycStatus.checking;
  }

  static UccKycStatus _resolveOverallKycStatus({
    required List<UccKycStatus> statuses,
    required List<bool> hasHolderFlags,
  }) {
    final activeStatuses = <UccKycStatus>[];
    for (var i = 0; i < hasHolderFlags.length; i++) {
      if (!hasHolderFlags[i]) {
        continue;
      }
      activeStatuses.add(statuses[i]);
    }

    if (activeStatuses.isEmpty) {
      return UccKycStatus.checking;
    }
    if (activeStatuses.contains(UccKycStatus.rejected)) {
      return UccKycStatus.rejected;
    }
    if (activeStatuses.contains(UccKycStatus.registered)) {
      return UccKycStatus.registered;
    }
    if (activeStatuses.any((status) => status == UccKycStatus.checking)) {
      return UccKycStatus.checking;
    }
    return UccKycStatus.validated;
  }

  static String _determineBseStatus(Map<String, dynamic> json) {
    final hasNominee =
        (_readString(json['Nomination_Flag']) ?? '').toUpperCase() == 'Y';
    final panValid =
        (_readString(json['Primary_Holder_PAN_Aadhaar_Status']) ?? '')
            .toUpperCase() ==
        'VALID';
    final bankValid = _hasAnyValidBankStatus(json);

    return hasNominee && panValid && bankValid ? 'Active' : 'Inactive';
  }

  static UccKycStatus _statusForPan(
    String pan,
    Map<String, UccKycStatus> kycStatusByPan,
  ) {
    if (pan.isEmpty) {
      return UccKycStatus.checking;
    }
    return kycStatusByPan[pan.toUpperCase()] ?? UccKycStatus.checking;
  }

  static bool _hasAnyValidBankStatus(Map<String, dynamic> json) {
    return List<int>.generate(5, (index) => index + 1).any((idx) {
      final status = (_readString(json['Bank${idx}_Status']) ?? '')
          .toUpperCase();
      return status == 'VALID';
    });
  }

  static List<UccBankDetail> _extractBanks(Map<String, dynamic> json) {
    final banks = <UccBankDetail>[];

    for (var idx = 1; idx <= 5; idx++) {
      final bankName = _readString(json['Bank_Name_$idx']) ?? '';
      final accountNumber = _readString(json['Account_No_$idx']) ?? '';
      if (bankName.isEmpty || accountNumber.isEmpty) {
        continue;
      }
      banks.add(
        UccBankDetail(
          index: idx,
          bankName: bankName,
          accountNumber: accountNumber,
          status: (_readString(json['Bank${idx}_Status']) ?? '').toUpperCase(),
        ),
      );
    }

    return banks;
  }

  static List<String> _extractNomineeNames(Map<String, dynamic> json) {
    final nominees = <String>[];
    for (var idx = 1; idx <= 3; idx++) {
      final nomineeName = _readString(json['Nominee_${idx}_Name']) ?? '';
      if (nomineeName.isNotEmpty) {
        nominees.add(nomineeName);
      }
    }
    return nominees;
  }
}

String? _readString(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is Map) {
    final dynamic mappedValue =
        value[r'$numberDouble'] ?? value[r'$numberLong'];
    if (mappedValue == null) {
      return null;
    }
    final mappedString = mappedValue.toString().trim();
    if (mappedString.isEmpty || mappedString.toUpperCase() == 'NAN') {
      return null;
    }
    return mappedString;
  }

  final result = value.toString().trim();
  if (result.isEmpty ||
      result.toLowerCase() == 'null' ||
      result.toUpperCase() == 'NAN') {
    return null;
  }
  return result;
}
