import 'dart:typed_data';

enum InvestwellReportType { capitalGain, portfolio }

const String investwellInvestorSearchQueryDocument =
    'query Search(\$searchAll: Boolean, \$searchQuery: String) { '
    'searchMintDb(searchAll: \$searchAll, searchQuery: \$searchQuery) { '
    'name pan mobile familyHead } }';

class InvestwellReportRequest {
  final InvestwellReportType type;
  final String pan;
  final int? year;

  const InvestwellReportRequest({
    required this.type,
    required this.pan,
    this.year,
  });
}

class InvestwellInvestorSearchRequest {
  final bool searchAll;
  final String searchQuery;

  const InvestwellInvestorSearchRequest({
    this.searchAll = false,
    required this.searchQuery,
  });

  Map<String, dynamic> toJson() {
    return {
      'query': investwellInvestorSearchQueryDocument,
      'variables': {'searchAll': searchAll, 'searchQuery': searchQuery.trim()},
    };
  }
}

class InvestwellReportFile {
  final InvestwellReportType type;
  final Uint8List bytes;
  final String contentType;
  final String fileName;
  final String pan;
  final int? year;

  const InvestwellReportFile({
    required this.type,
    required this.bytes,
    required this.contentType,
    required this.fileName,
    required this.pan,
    this.year,
  });
}

class InvestwellInvestorModel {
  final String name;
  final String pan;
  final String familyHead;
  final String mobile;

  const InvestwellInvestorModel({
    required this.name,
    required this.pan,
    required this.familyHead,
    required this.mobile,
  });

  factory InvestwellInvestorModel.fromJson(Map<String, dynamic> json) {
    String parseStr(dynamic val) {
      if (val == null) {
        return '';
      }
      if (val is Map) {
        return val[r'$numberDouble']?.toString() ??
            val[r'$numberLong']?.toString() ??
            '';
      }
      final s = val.toString().trim();
      if (s.toLowerCase() == 'null' || s.toUpperCase() == 'NAN') {
        return '';
      }
      return s;
    }

    String readValue(List<String> keys) {
      for (final key in keys) {
        final value = parseStr(json[key]);
        if (value.isNotEmpty) {
          return value;
        }
      }
      return '';
    }

    return InvestwellInvestorModel(
      name: readValue(const ['name', 'NAME']),
      pan: readValue(const ['pan', 'PAN']).toUpperCase(),
      familyHead: readValue(const ['familyHead', 'FAMILY HEAD']),
      mobile: readValue(const ['mobile', 'MOBILE']),
    );
  }
}
