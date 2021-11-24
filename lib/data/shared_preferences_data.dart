import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesData {
  static const memeKey = "favorite_superheroes";

  static SharedPreferencesData? _instance;

  factory SharedPreferencesData.getInstance() => _instance ??= SharedPreferencesData._internal();

  SharedPreferencesData.internal();

  Future<bool> setMemes(final List<String> memes) async {
    final sp = await SharedPreferences.getInstance();
    final result = sp.setStringList(memeKey, memes);
    return result;
  }

  Future<List<String>> getMemes() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getStringList(memeKey) ?? [];
  }
}
