import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:memogenerator/data/models/template.dart';
import 'package:memogenerator/data/shared_preference_data.dart';
import 'package:rxdart/rxdart.dart';

class TemplatesRepository {
  final updater = PublishSubject<Null>();
  final SharedPreferencesData spData;

  static TemplatesRepository? _instance;

  factory TemplatesRepository.getInstance() =>
      _instance ??= TemplatesRepository._internal(SharedPreferencesData.getInstance());

  TemplatesRepository._internal(this.spData);

  Future<bool> addToTemplates(final Template template) async {
    final raw = await spData.getTemplates();
    final existentTemplateIndex = raw.indexWhere((element) => element.contains(template.id));
    if (existentTemplateIndex > -1) {
      raw.removeAt(existentTemplateIndex);
      raw.insert(existentTemplateIndex, json.encode(template.toJson()));
    } else {
      raw.add(json.encode(template.toJson()));
    }

    return _setRawTemplates(raw);
  }

  Future<bool> removeFromTemplates(final String id) async {
    final templates = await getTemplates();
    templates.removeWhere((e) => e.id == id);
    return _setTemplates(templates);
  }

  Stream<List<Template>> observeTemplates() async* {
    yield await getTemplates();
    await for (final _ in updater) {
      yield await getTemplates();
    }
  }

  Future<List<Template>> getTemplates() async {
    final raw = await spData.getTemplates();
    return raw.map((e) => Template.fromJson(json.decode(e) as Map<String, dynamic>)).toList();
  }

  Future<Template?> getTemplate(final String id) async {
    final list = await getTemplates();
    return list.firstWhereOrNull((e) => e.id == id);
  }

  Future<bool> _setTemplates(final List<Template> templates) async {
    final raw = templates.map((e) => json.encode(e.toJson())).toList();
    return _setRawTemplates(raw);
  }

  Future<bool> _setRawTemplates(final List<String> rawList) {
    updater.add(null);
    return spData.setTemplates(rawList);
  }
}
