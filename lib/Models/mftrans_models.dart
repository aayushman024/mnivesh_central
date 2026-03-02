class UccModel {
  final String name;
  final String id;
  final String bseStatus;
  final String bank;
  final String nominee;
  final bool isValidated;

  UccModel({
    required this.name,
    required this.id,
    required this.bseStatus,
    required this.bank,
    required this.nominee,
    required this.isValidated,
  });
}

class InvestorModel {
  final String name;
  final String pan;
  final String familyHead;

  InvestorModel({
    required this.name,
    required this.pan,
    required this.familyHead,
  });
}