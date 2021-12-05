import 'dart:convert';

import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/shared_preferences_data.dart';
import 'package:rxdart/rxdart.dart';
import 'package:collection/collection.dart';

class MemesRepository {
  final updater = PublishSubject<Null>();
  final SharedPreferencesData spData;

  static MemesRepository? _instance;

  factory MemesRepository.getInstance() =>
      _instance ??= MemesRepository._internal(SharedPreferencesData.getInstance());

  MemesRepository._internal(this.spData);

  Future<bool> addToMemes(final Meme meme) async {
    final raw = await spData.getMemes();
    final existentMemeIndex = raw.indexWhere((element) => element.contains(meme.id));
    if (existentMemeIndex > -1) {
      raw.removeAt(existentMemeIndex);
      raw.insert(existentMemeIndex, json.encode(meme.toJson()));
    } else {
      raw.add(json.encode(meme.toJson()));
    }

    return _setRawMemes(raw);
  }

  Future<bool> removeFromMemes(final String id) async {
    final memes = await getMemes();
    memes.removeWhere((e) => e.id == id);
    return _setMemes(memes);
  }

  Stream<List<Meme>> observeMemes() async* {
    yield await getMemes();
    await for (final _ in updater) {
      yield await getMemes();
    }
  }

  Future<List<Meme>> getMemes() async {
    final raw = await spData.getMemes();
    return raw.map((e) => Meme.fromJson(json.decode(e) as Map<String, dynamic>)).toList();
  }

  Future<Meme?> getMeme(final String id) async {
    final list = await getMemes();
    return list.firstWhereOrNull((e) => e.id == id);
  }

  Future<bool> _setMemes(final List<Meme> memes) async {
    final raw = memes.map((e) => json.encode(e.toJson())).toList();
    return _setRawMemes(raw);
  }

  Future<bool> _setRawMemes(final List<String> rawList) {
    updater.add(null);
    return spData.setMemes(rawList);
  }
}
