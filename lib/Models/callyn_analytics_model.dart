class CallLogAnalyticsModel {
  final List<dynamic> mostCallsMade;
  final List<dynamic> mostWorkCallDuration;
  final List<dynamic> mostPersonalCallDuration;
  final List<dynamic> mostFrequentlyCalledClients;
  final List<dynamic> mostCalledClientsByDuration;
  final List<dynamic> dailyCallVolume;
  final List<dynamic> missedOrRejectedPerEmployee;
  final List<dynamic> avgCallDurationPerEmployee;
  final List<dynamic> callTypeBreakdown;
  final List<dynamic> topClientPerEmployee; // new metric

  CallLogAnalyticsModel({
    required this.mostCallsMade,
    required this.mostWorkCallDuration,
    required this.mostPersonalCallDuration,
    required this.mostFrequentlyCalledClients,
    required this.mostCalledClientsByDuration,
    required this.dailyCallVolume,
    required this.missedOrRejectedPerEmployee,
    required this.avgCallDurationPerEmployee,
    required this.callTypeBreakdown,
    required this.topClientPerEmployee,
  });

  factory CallLogAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'] ?? {};
    return CallLogAnalyticsModel(
      mostCallsMade: metrics['mostCallsMade'] ?? metrics['callsPerEmployee'] ?? [],
      mostWorkCallDuration: metrics['mostWorkCallDuration'] ?? metrics['workDurationPerEmployee'] ?? [],
      mostPersonalCallDuration: metrics['mostPersonalCallDuration'] ?? metrics['personalDurationPerEmployee'] ?? [],
      mostFrequentlyCalledClients: metrics['mostFrequentlyCalledClients'] ?? metrics['clientFrequency'] ?? [],
      mostCalledClientsByDuration: metrics['mostCalledClientsByDuration'] ?? metrics['clientDuration'] ?? [],
      dailyCallVolume: metrics['dailyCallVolume'] ?? metrics['dailyVolume'] ?? [],
      missedOrRejectedPerEmployee: metrics['missedOrRejectedPerEmployee'] ?? metrics['missedRejectedPerEmployee'] ?? [],
      avgCallDurationPerEmployee: metrics['avgCallDurationPerEmployee'] ?? [],
      callTypeBreakdown: metrics['callTypeBreakdown'] ?? [],
      topClientPerEmployee: metrics['topClientPerEmployee'] ?? [], // map from json
    );
  }
}