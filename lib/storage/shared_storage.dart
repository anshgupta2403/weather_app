// shared_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/models/app_weather.dart';

class SharedStorage {
  static const _citiesKey = 'cities';
  static const _weatherPrefix = 'weather_';
  static const _userCountry = 'country';
  static const _userCountryCode = 'countryCode';
  final SharedPreferences _prefs;

  SharedStorage._(this._prefs);

  static Future<SharedStorage> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedStorage._(prefs);
  }

  List<String> getCities() {
    return _prefs.getStringList(_citiesKey) ?? [];
  }

  Future<void> saveCities(List<String> cities) async {
    await _prefs.setStringList(_citiesKey, cities);
  }

  Future<void> saveWeather(String city, AppWeather weather) async {
    String key = '$_weatherPrefix$city';
    String jsonStr = jsonEncode(weather.toJson());
    await _prefs.setString(key, jsonStr);
  }

  AppWeather? getWeather(String city) {
    String key = '$_weatherPrefix$city';
    final jsonStr = _prefs.getString(key);
    if (jsonStr == null) return null;
    final Map<String, dynamic> jsonMap = jsonDecode(jsonStr);
    return AppWeather.fromJson(jsonMap);
  }

  Future<void> saveCountry(String country) async {
    await _prefs.setString(_userCountry, country);
  }

  String getCountry() {
    return _prefs.getString(_userCountry) ?? '';
  }

  Future<void> saveCountryCode(String countryCode) async {
    await _prefs.setString(_userCountryCode, countryCode);
  }

  String getCountryCode() {
    return _prefs.getString(_userCountryCode) ?? '';
  }
}
