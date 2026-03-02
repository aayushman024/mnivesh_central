// lib/Models/mftrans_models.dart

class InvestorModel {
  final String name;
  final String pan;
  final String familyHead;

  const InvestorModel({
    required this.name,
    required this.pan,
    required this.familyHead,
  });

  // TODO: factory InvestorModel.fromJson(Map<String, dynamic> json) => InvestorModel(
  //   name: json['name'],
  //   pan: json['pan'],
  //   familyHead: json['familyHead'],
  // );
}

class UccModel {
  final String name;
  final String id;
  final String bseStatus;
  final String bank;
  final String nominee;
  final bool isValidated;

  const UccModel({
    required this.name,
    required this.id,
    required this.bseStatus,
    required this.bank,
    required this.nominee,
    required this.isValidated,
  });

  // TODO: factory UccModel.fromJson(Map<String, dynamic> json) => UccModel(
  //   name: json['name'],
  //   id: json['id'],
  //   bseStatus: json['bseStatus'],
  //   bank: json['bank'],
  //   nominee: json['nominee'],
  //   isValidated: json['isValidated'] ?? false,
  // );
}
