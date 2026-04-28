import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthManager {
  static const String _authToken = "AuthToken";
  static const String _refreshToken = "RefreshToken";
  static const String _isLoggedIn = "IsLoggedIn";
  static const String _tokenType = "TokenType";
  static const String _tokenKid = "TokenKid";
  static const String _pendingLoginStartedAt = "PendingLoginStartedAt";
  static const String _userName = "UserName";
  static const String _userEmail = "UserEmail";
  static const String _userDepartment = "user_department";
  static const String _workPhone = "workPhone";
  static const String _appBackendTokenPrefix = "AppBackendToken_";
  static const String _appBackendTokenKeys = "AppBackendTokenKeys";
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  static const IOSOptions _iosOptions = IOSOptions();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  // ── In-memory cache (populated by hydrate / write-through on saves) ──
  static String? _cachedAccessToken;
  static String? _cachedRefreshToken;
  static String? _cachedTokenType;
  static String? _cachedKid;
  static String? _cachedUserName;
  static String? _cachedUserEmail;
  static String? _cachedUserDepartment;
  static Map<String, String> _cachedAppBackendTokens = {};
  static bool _isLogoutInProgress = false;

  // ── Sync getters (read from in-memory cache) ──
  static String? get accessToken => _cachedAccessToken;
  static String? get refreshToken => _cachedRefreshToken;
  static String? get tokenType => _cachedTokenType;
  static String? get kid => _cachedKid;
  static String? get userName => _cachedUserName;
  static String? get userEmail => _cachedUserEmail;
  static String? get department => _cachedUserDepartment;
  static bool get isLogoutInProgress => _isLogoutInProgress;

  /// Returns the cached app-backend token for [appKey], or null if not found.
  static String? getAppToken(String appKey) {
    final normalizedKey = _normalizeAppKey(appKey);
    if (normalizedKey == null) return null;
    return _cachedAppBackendTokens[normalizedKey];
  }

  /// Returns an unmodifiable view of all cached app-backend tokens.
  static Map<String, String> get appBackendTokens =>
      Map<String, String>.unmodifiable(_cachedAppBackendTokens);

  // ──────────────────────────────────────────────────────────────
  // Hydrate — call once at cold-start, and on every app resume.
  // Loads tokens from secure storage / shared preferences into
  // the in-memory cache for instant synchronous access.
  // ──────────────────────────────────────────────────────────────
  static Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();

    _cachedAccessToken = await _secureStorage.read(key: _authToken);
    _cachedRefreshToken = await _secureStorage.read(key: _refreshToken);
    _cachedTokenType = prefs.getString(_tokenType);
    _cachedKid = prefs.getString(_tokenKid);
    _cachedUserName = prefs.getString(_userName);
    _cachedUserEmail = prefs.getString(_userEmail);
    _cachedUserDepartment = prefs.getString(_userDepartment);
    _cachedAppBackendTokens = await _loadAppBackendTokensFromStorage(prefs);

    debugPrint(
      '[AuthManager] Hydrated token cache. '
      'accessToken=${_cachedAccessToken != null ? "present" : "null"}, '
      'refreshToken=${_cachedRefreshToken != null ? "present" : "null"}, '
      'appTokens=${_cachedAppBackendTokens.length}',
    );
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedIn) ?? false;
  }

  static Future<Map<String, dynamic>?> decodeAndPrintAccessToken() async {
    final token = _cachedRefreshToken;

    if (token == null || token.isEmpty) {
      debugPrint('[AuthManager] No access token found in storage.');
      return null;
    }

    final parts = token.split('.');
    if (parts.length != 3) {
      debugPrint('[AuthManager] Invalid JWT — expected 3 parts, got ${parts.length}.');
      return null;
    }

    String normalizePadding(String input) {
      String output = input.replaceAll('-', '+').replaceAll('_', '/');
      switch (output.length % 4) {
        case 2: output += '=='; break;
        case 3: output += '=';  break;
      }
      return output;
    }

    try {
      final headerJson  = utf8.decode(base64.decode(normalizePadding(parts[0])));
      final payloadJson = utf8.decode(base64.decode(normalizePadding(parts[1])));

      final Map<String, dynamic> payload = jsonDecode(payloadJson);

      final encoder = JsonEncoder.withIndent('  ');
      debugPrint('[AuthManager] ── JWT Header  ──\n${encoder.convert(jsonDecode(headerJson))}');
      debugPrint('[AuthManager] ── JWT Payload ──\n${encoder.convert(payload)}');

      return payload;
    } catch (e) {
      debugPrint('[AuthManager] Failed to decode token: $e');
      return null;
    }
  }

  static Future<void> saveAuthSession({
    required String accessToken,
    String? refreshToken,
    String? tokenType,
    String? kid,
    String? name,
    String? email,
    String? associatedNumber,
    String? departmentName,
  }) async {
    if (_isLogoutInProgress) {
      debugPrint('[AuthManager] Ignoring session save during logout.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await _secureStorage.write(key: _authToken, value: accessToken);
    _cachedAccessToken = accessToken;

    await prefs.setBool(_isLoggedIn, true);

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secureStorage.write(key: _refreshToken, value: refreshToken);
      _cachedRefreshToken = refreshToken;
    }

    if (tokenType != null && tokenType.isNotEmpty) {
      await prefs.setString(_tokenType, tokenType);
      _cachedTokenType = tokenType;
    }

    if (kid != null && kid.isNotEmpty) {
      await prefs.setString(_tokenKid, kid);
      _cachedKid = kid;
    }

    await _persistUserData(
      prefs,
      name: name,
      email: email,
      associatedNumber: associatedNumber,
      departmentName: departmentName,
    );
  }

  static Future<void> updateAccessToken({
    required String accessToken,
    String? tokenType,
    String? kid,
    String? associatedNumber,
    String? departmentName,
  }) async {
    if (_isLogoutInProgress) {
      debugPrint('[AuthManager] Ignoring token refresh during logout.');
      return;
    }

    await saveAuthSession(
      accessToken: accessToken,
      refreshToken: _cachedRefreshToken,
      tokenType: tokenType ?? _cachedTokenType,
      kid: kid ?? _cachedKid,
      name: _cachedUserName,
      email: _cachedUserEmail,
      associatedNumber: associatedNumber,
      departmentName: departmentName,
    );
  }

  static Future<void> markLoginFlowStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _pendingLoginStartedAt,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<void> clearPendingLoginFlow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingLoginStartedAt);
  }

  static Future<bool> consumePendingLoginFlow({
    Duration maxAge = const Duration(minutes: 10),
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final startedAtMillis = prefs.getInt(_pendingLoginStartedAt);

    if (startedAtMillis == null) {
      return false;
    }

    await prefs.remove(_pendingLoginStartedAt);

    final startedAt = DateTime.fromMillisecondsSinceEpoch(startedAtMillis);
    final age = DateTime.now().difference(startedAt);
    return age <= maxAge;
  }

  /// Reads app-backend tokens directly from secure storage.
  /// Used internally by [saveAppBackendTokens] and [clearStoredAppBackendTokens].
  /// For fast reads, use the synchronous [appBackendTokens] getter instead.
  static Future<Map<String, String>> getStoredAppBackendTokens() async {
    // DON'T use readAll() — unreliable with encryptedSharedPreferences on Android
    final prefs = await SharedPreferences.getInstance();
    return _loadAppBackendTokensFromStorage(prefs);
  }

  static Future<void> saveAppBackendTokens(
    Map<String, String> appTokens,
  ) async {
    final normalizedTokens = <String, String>{};
    for (final entry in appTokens.entries) {
      final appKey = _normalizeAppKey(entry.key);
      final token = _normalize(entry.value);
      if (appKey == null || token == null) continue;
      normalizedTokens[appKey] = token;
    }

    final existingTokens = await getStoredAppBackendTokens();
    final writes = <Future<void>>[];

    for (final entry in normalizedTokens.entries) {
      if (existingTokens[entry.key] == entry.value) continue;
      writes.add(
        _secureStorage.write(
          key: appBackendTokenStorageKey(entry.key),
          value: entry.value,
        ),
      );
    }

    for (final appKey in existingTokens.keys) {
      if (normalizedTokens.containsKey(appKey)) continue;
      writes.add(_secureStorage.delete(key: appBackendTokenStorageKey(appKey)));
    }

    if (writes.isNotEmpty) await Future.wait(writes);

    // Persist the key index so getStoredAppBackendTokens can read without readAll()
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _appBackendTokenKeys,
      normalizedTokens.keys.toList(),
    );

    // Write-through to in-memory cache
    _cachedAppBackendTokens = Map<String, String>.from(normalizedTokens);

    debugPrint('[AuthManager] Total tokens saved: ${normalizedTokens.length}');
    for (final entry in normalizedTokens.entries) {
      debugPrint(
        '[AuthManager]  key=${entry.key}  token=${entry.value.substring(0, 8)}...',
      );
    }
  }

  static Future<void> logout() async {
    if (_isLogoutInProgress) {
      return;
    }

    _isLogoutInProgress = true;
    final prefs = await SharedPreferences.getInstance();
    try {
      _cachedAccessToken = null;
      _cachedRefreshToken = null;
      _cachedTokenType = null;
      _cachedKid = null;
      _cachedUserName = null;
      _cachedUserEmail = null;
      _cachedUserDepartment = null;
      _cachedAppBackendTokens = {};

      await Future.wait([
        _deleteSecureKeyRobustly(_authToken),
        _deleteSecureKeyRobustly(_refreshToken),
        prefs.remove(_pendingLoginStartedAt),
      ]);
      await clearStoredAppBackendTokens();
      await Future.wait([
        prefs.setBool(_isLoggedIn, false),
        prefs.remove(_tokenType),
        prefs.remove(_tokenKid),
        prefs.remove(_userName),
        prefs.remove(_userEmail),
        prefs.remove(_userDepartment),
        prefs.remove(_workPhone),
      ]);
      await _verifyLoggedOutState(prefs);
    } finally {
      _isLogoutInProgress = false;
    }
  }

  static Future<void> clearStoredAppBackendTokens() async {
    final existingTokens = await getStoredAppBackendTokens();
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      for (final appKey in existingTokens.keys)
        _secureStorage.delete(key: appBackendTokenStorageKey(appKey)),
    ]);

    await prefs.remove(_appBackendTokenKeys); // ← clear the index too
    _cachedAppBackendTokens = {};
  }

  static String appBackendTokenStorageKey(String appKey) {
    return '$_appBackendTokenPrefix${appKey.toUpperCase()}';
  }

  // ── Private helpers ──

  static Future<void> _deleteSecureKeyRobustly(String key) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      await _secureStorage.delete(key: key);
      final remaining = await _secureStorage.read(key: key);
      if (_normalize(remaining) == null) {
        return;
      }

      await _secureStorage.write(key: key, value: '');
      await _secureStorage.delete(key: key);
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }

    final remaining = await _secureStorage.read(key: key);
    if (_normalize(remaining) != null) {
      debugPrint(
        '[AuthManager] Secure storage key still present after logout: $key',
      );
    }
  }

  static Future<void> _verifyLoggedOutState(SharedPreferences prefs) async {
    final storedAccessToken = await _secureStorage.read(key: _authToken);
    final storedRefreshToken = await _secureStorage.read(key: _refreshToken);

    if (_normalize(storedAccessToken) != null ||
        _normalize(storedRefreshToken) != null) {
      debugPrint(
        '[AuthManager] Logout verification found lingering auth tokens.',
      );
    }

    _cachedAccessToken = null;
    _cachedRefreshToken = null;
    _cachedTokenType = null;
    _cachedKid = null;
    _cachedUserName = null;
    _cachedUserEmail = null;
    _cachedUserDepartment = null;
    _cachedAppBackendTokens = {};

    if (prefs.getBool(_isLoggedIn) ?? false) {
      await prefs.setBool(_isLoggedIn, false);
    }
  }

  static Future<Map<String, String>> _loadAppBackendTokensFromStorage(
    SharedPreferences prefs,
  ) async {
    final knownAppKeys = prefs.getStringList(_appBackendTokenKeys) ?? [];
    final tokens = <String, String>{};
    for (final appKey in knownAppKeys) {
      final token = await _secureStorage.read(
        key: appBackendTokenStorageKey(appKey),
      );
      final normalized = _normalize(token);
      if (normalized != null) {
        tokens[appKey] = normalized;
      }
    }
    return tokens;
  }

  static Future<void> _persistUserData(
    SharedPreferences prefs, {
    String? name,
    String? email,
    String? associatedNumber,
    String? departmentName,
  }) async {
    final resolvedName = _normalize(name);
    final resolvedEmail = _normalize(email);
    final department = _normalize(departmentName);
    final number = _normalize(associatedNumber);

    if (resolvedName != null && resolvedName.isNotEmpty) {
      await prefs.setString(_userName, resolvedName);
      _cachedUserName = resolvedName;
    }
    if (resolvedEmail != null && resolvedEmail.isNotEmpty) {
      await prefs.setString(_userEmail, resolvedEmail);
      _cachedUserEmail = resolvedEmail;
    }
    if (department != null && department.isNotEmpty) {
      await prefs.setString(_userDepartment, department);
      _cachedUserDepartment = department;
    }
    if (number != null && number.isNotEmpty) {
      await prefs.setString(_workPhone, number);
    }
  }

  static String? _normalize(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    if (trimmed.toLowerCase() == 'null') {
      return null;
    }
    return trimmed;
  }

  static String? _normalizeAppKey(String? appKey) {
    final normalized = _normalize(appKey);
    return normalized?.toUpperCase();
  }
}
