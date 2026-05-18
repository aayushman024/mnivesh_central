import 'dart:typed_data';

enum InvestwellReportType { capitalGain, portfolio }

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
