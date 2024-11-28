import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesService {
  // Singleton instance
  static final SharedPreferencesService _instance = SharedPreferencesService._internal();

  factory SharedPreferencesService() {
    return _instance;
  }

  SharedPreferencesService._internal();

  SharedPreferences? _prefs;

  // Инициализация SharedPreferences
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Сохранение данных
  Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  Future<void> setString(String key, String value) async {
    await _prefs?.setString(key, value);
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  // Получение данных
  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  String? getString(String key) {
    return _prefs?.getString(key);
  }

  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  // Удаление данных
  Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  // Очистка всех данных
  Future<void> clear() async {
    await _prefs?.clear();
  }
}
