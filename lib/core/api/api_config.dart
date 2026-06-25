class ApiConfig {
  const ApiConfig._();

  static const String appVersion = "2.1.6";

  static const String localBaseUrl = String.fromEnvironment('LOCAL_BASE_URL');
  static const String emulatorBaseUrl = String.fromEnvironment('EMULATOR_BASE_URL');
  static const String prodBaseUrl = String.fromEnvironment('PROD_BASE_URL');

  static const String blobBaseUrl = String.fromEnvironment('BLOB_BASE_URL');

  static const String defaultBaseUrl = String.fromEnvironment('DEFAULT_BASE_URL');

  static const String centralAppKey = String.fromEnvironment('CENTRAL_APP_KEY');
  static const String mobileRedirectUri = String.fromEnvironment('MOBILE_REDIRECT_URI');

  static const String callynAnalyticsBaseUrl = String.fromEnvironment('CALLYN_ANALYTICS_BASE_URL');

  static const String operationsBaseUrl = String.fromEnvironment('OPERATIONS_BASE_URL');
  static const String operationsAppKey = String.fromEnvironment('OPERATIONS_APP_KEY');

  static const String attendanceBaseUrl = String.fromEnvironment('ATTENDANCE_BASE_URL');
  static const String daftarAppKey = String.fromEnvironment('DAFTAR_APP_KEY');

  static const String internalBaseURL = String.fromEnvironment('INTERNAL_BASE_URL');

  static const String marketingBaseUrl = String.fromEnvironment('MARKETING_BASE_URL');
  static const String marketingAppKey = String.fromEnvironment('MARKETING_APP_KEY');

  static const String routeOptimizationBaseUrl = String.fromEnvironment('ROUTE_OPTIMIZATION_BASE_URL');
  static const String routeAppKey = String.fromEnvironment('ROUTE_APP_KEY');

  static const String googleMapsAPIKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
}