import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesData {
  static const memeKey = "meme_key";
  static const templateKey = "template_key";

  static SharedPreferencesData? _instance;

  factory SharedPreferencesData.getInstance() => _instance ??= SharedPreferencesData._internal();

  SharedPreferencesData._internal();

  Future<bool> setMemes(final List<String> memes) => setItems(memeKey, memes);

  Future<bool> setTemplates(final List<String> templates) => setItems(templateKey, templates);

  Future<List<String>> getMemes() => getItems(memeKey);

  Future<List<String>> getTemplates() => getItems(templateKey);

  Future<bool> setItems(
    final String key,
    final List<String> items,
  ) async {
    final sp = await SharedPreferences.getInstance();
    final result = sp.setStringList(key, items);
    return result;
  }

  Future<List<String>> getItems(final String key) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getStringList(key) ?? [];
  }
}
