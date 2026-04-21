class ApiConfig {
  const ApiConfig._();

  static const String appVersion = "2.0.0";

  static const String localBaseUrl = 'http://192.168.1.74:5500';
  static const String prodBaseUrl = 'https://app-store-dqg8bnf4d8cberf7.centralindia-01.azurewebsites.net';

  static const String defaultBaseUrl = localBaseUrl;

  static const String centralAppKey = 'MNIVESH_CENTRAL';
  static const String mobileRedirectUri = 'mniveshcentral://auth/callback';

  static const String callynAnalyticsBaseUrl = 'https://callyn-backend-avh8cae5dpdnckg8.centralindia-01.azurewebsites.net';

  static const String operationsBaseUrl = 'https://ops-api.mnivesh.com';
  static const String operationsAppKey = 'OPERATIONS';

  static const String attendanceBaseUrl = 'https://daftar-api.aria.mnivesh.com';
  static const String daftarAppKey = 'MNIVESH_DAFTAR';

  static const String marketingBaseUrl = 'https://daftar-api.aria.mnivesh.com';
  static const String marketingAppKey = 'INTERNAL_MFRESEARCH';
}

