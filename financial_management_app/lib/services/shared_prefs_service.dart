import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const String _themeKey = 'theme_mode';
  static const String _currencyKey = 'currency';
  static const String _firstLaunchKey = 'first_launch';
  static const String _userNameKey = 'user_name';
  static const String _budgetAlertKey = 'budget_alert';
  
  Future<SharedPreferences> get _prefs async {
    return await SharedPreferences.getInstance();
  }
  
  // Theme
  Future<void> setThemeMode(String themeMode) async {
    final prefs = await _prefs;
    await prefs.setString(_themeKey, themeMode);
  }
  
  Future<String> getThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(_themeKey) ?? 'system';
  }
  
  // Currency
  Future<void> setCurrency(String currency) async {
    final prefs = await _prefs;
    await prefs.setString(_currencyKey, currency);
  }
  
  Future<String> getCurrency() async {
    final prefs = await _prefs;
    return prefs.getString(_currencyKey) ?? 'IDR';
  }
  
  // User name
  Future<void> setUserName(String name) async {
    final prefs = await _prefs;
    await prefs.setString(_userNameKey, name);
  }
  
  Future<String> getUserName() async {
    final prefs = await _prefs;
    return prefs.getString(_userNameKey) ?? 'User';
  }
  
  // Budget alerts
  Future<void> setBudgetAlert(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_budgetAlertKey, enabled);
  }
  
  Future<bool> getBudgetAlert() async {
    final prefs = await _prefs;
    return prefs.getBool(_budgetAlertKey) ?? true;
  }
  
  // First launch
  Future<bool> isFirstLaunch() async {
    final prefs = await _prefs;
    final isFirst = prefs.getBool(_firstLaunchKey) ?? true;
    if (isFirst) {
      await prefs.setBool(_firstLaunchKey, false);
    }
    return isFirst;
  }
  
  // Clear all data (for logout)
  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}