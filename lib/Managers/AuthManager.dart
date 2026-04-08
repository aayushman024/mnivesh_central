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

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      _secureStorage.delete(key: _authToken),
      _secureStorage.delete(key: _refreshToken),
    ]);
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

  static Future<void> _persistUserData(
    SharedPreferences prefs,
    {
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
}
