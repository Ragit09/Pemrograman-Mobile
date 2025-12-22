import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  static SharedPreferences? _preferences;

  static Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    if (_preferences == null) await init();
    
    for (var entry in userData.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is String) {
        await _preferences!.setString(key, value);
      } else if (value is int) {
        await _preferences!.setInt(key, value);
      } else if (value is bool) {
        await _preferences!.setBool(key, value);
      } else if (value is double) {
        await _preferences!.setDouble(key, value);
      } else if (value is Map<String, dynamic>) {
        // Handle nested map (untuk survey data)
        await _preferences!.setString(key, value.toString());
      }
    }
  }

  static Future<Map<String, dynamic>> getUserData() async {
    if (_preferences == null) await init();
    
    // BUAT MAP BARU BUKAN RETURN LANGSUNG
    final userData = <String, dynamic>{};
    
    userData['email'] = _preferences!.getString('email') ?? '';
    userData['password'] = _preferences!.getString('password') ?? '';
    userData['fullName'] = _preferences!.getString('fullName') ?? '';
    userData['phone'] = _preferences!.getString('phone') ?? '';
    userData['bio'] = _preferences!.getString('bio') ?? '';
    userData['gender'] = _preferences!.getString('gender') ?? 'Laki-laki';
    userData['rememberMe'] = _preferences!.getBool('rememberMe') ?? false;
    userData['birthDate'] = _preferences!.getString('birthDate');
    
    return userData; // RETURN MAP YANG BISA DIUBAH
  }

  static Future<void> clearUserData() async {
    if (_preferences == null) await init();
    await _preferences!.clear();
  }
}