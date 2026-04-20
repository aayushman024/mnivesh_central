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
  static const String _userName = "UserName";
  static const String _userEmail = "UserEmail";
  static const String _userDepartment = "user_department";
  static const String _workPhone = "workPhone";
  static const String _appBackendTokenPrefix = "AppBackendToken_";
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  static const IOSOptions _iosOptions = IOSOptions();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedIn) ?? false;
  }

  // static Future<Map<String, dynamic>?> decodeAndPrintAccessToken() async {
  //   final token = await getRefreshToken();
  //
  //   if (token == null || token.isEmpty) {
  //     debugPrint('[AuthManager] No access token found in storage.');
  //     return null;
  //   }
  //
  //   final parts = token.split('.');
  //   if (parts.length != 3) {
  //     debugPrint('[AuthManager] Invalid JWT — expected 3 parts, got ${parts.length}.');
  //     return null;
  //   }
  //
  //   String normalizePadding(String input) {
  //     String output = input.replaceAll('-', '+').replaceAll('_', '/');
  //     switch (output.length % 4) {
  //       case 2: output += '=='; break;
  //       case 3: output += '=';  break;
  //     }
  //     return output;
  //   }
  //
  //   try {
  //     final headerJson  = utf8.decode(base64.decode(normalizePadding(parts[0])));
  //     final payloadJson = utf8.decode(base64.decode(normalizePadding(parts[1])));
  //
  //     final Map<String, dynamic> payload = jsonDecode(payloadJson);
  //
  //     final encoder = JsonEncoder.withIndent('  ');
  //     debugPrint('[AuthManager] ── JWT Header  ──\n${encoder.convert(jsonDecode(headerJson))}');
  //     debugPrint('[AuthManager] ── JWT Payload ──\n${encoder.convert(payload)}');
  //
  //     return payload;
  //   } catch (e) {
  //     debugPrint('[AuthManager] Failed to decode token: $e');
  //     return null;
  //   }
  // }

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
    final prefs = await SharedPreferences.getInstance();

    await _secureStorage.write(key: _authToken, value: accessToken);
    await prefs.setBool(_isLoggedIn, true);

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _secureStorage.write(key: _refreshToken, value: refreshToken);
    }

    if (tokenType != null && tokenType.isNotEmpty) {
      await prefs.setString(_tokenType, tokenType);
    }

    if (kid != null && kid.isNotEmpty) {
      await prefs.setString(_tokenKid, kid);
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
    final refreshToken = await getRefreshToken();

    await saveAuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType ?? await getTokenType(),
      kid: kid ?? await getKid(),
      name: await getUserName(),
      email: await _getStoredString(_userEmail),
      associatedNumber: associatedNumber,
      departmentName: departmentName,
    );
  }

  static Future<String?> getAccessToken() async {
    return _secureStorage.read(key: _authToken);
  }

  static Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: _refreshToken);
  }

  static Future<String?> getTokenType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenType);
  }

  static Future<String?> getKid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKid);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userName);
  }

  static Future<String?> _getStoredString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<String?> getAppBackendToken(String appKey) async {
    final normalizedAppKey = _normalizeAppKey(appKey);
    if (normalizedAppKey == null) {
      return null;
    }

    return _secureStorage.read(
      key: appBackendTokenStorageKey(normalizedAppKey),
    );
  }

  static Future<Map<String, String>> getStoredAppBackendTokens() async {
    // DON'T use readAll() — unreliable with encryptedSharedPreferences on Android
    final prefs = await SharedPreferences.getInstance();
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

  static const String _appBackendTokenKeys = "AppBackendTokenKeys";

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

    final saved = await getStoredAppBackendTokens();
    debugPrint('[AuthManager] Total tokens saved: ${saved.length}');
    for (final entry in saved.entries) {
      debugPrint('[AuthManager]  key=${entry.key}  token=${entry.value.substring(0, 10)}...');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      _secureStorage.delete(key: _authToken),
      _secureStorage.delete(key: _refreshToken),
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
  }

  static Future<void> clearStoredAppBackendTokens() async {
    final existingTokens = await getStoredAppBackendTokens();
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      for (final appKey in existingTokens.keys)
        _secureStorage.delete(key: appBackendTokenStorageKey(appKey)),
    ]);

    await prefs.remove(_appBackendTokenKeys); // ← clear the index too
  }

  static String appBackendTokenStorageKey(String appKey) {
    return '$_appBackendTokenPrefix${appKey.toUpperCase()}';
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
    }
    if (resolvedEmail != null && resolvedEmail.isNotEmpty) {
      await prefs.setString(_userEmail, resolvedEmail);
    }
    if (department != null && department.isNotEmpty) {
      await prefs.setString(_userDepartment, department);
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
