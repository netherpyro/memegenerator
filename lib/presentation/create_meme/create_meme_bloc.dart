import 'dart:async';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:rxdart/rxdart.dart';

import 'models/meme_text.dart';
import 'models/meme_text_offset.dart';

class CreateMemeBloc {
  final memeTextsSubject = BehaviorSubject<List<MemeText>>.seeded(<MemeText>[]);
  final selectedMemeTextSubject = BehaviorSubject<MemeText?>.seeded(null);
  final memeTextOffsetsSubject = BehaviorSubject<List<MemeTextOffset>>.seeded(<MemeTextOffset>[]);
  final newMemeTextOffsetSubject = BehaviorSubject<MemeTextOffset?>.seeded(null);

  StreamSubscription<MemeTextOffset?>? newMemeTextSubscription;

  CreateMemeBloc() {
    newMemeTextSubscription = newMemeTextOffsetSubject
    .debounceTime(Duration(milliseconds: 300))
        .listen((value) {
      if (value != null) {
        _changeMemeTextOffsetInternal(value);
      }
    }, onError: (e, st) => print("Error in newMemeTextOffsetSubject: $e, $st"));
  }

  void changeMemeTextOffset(final String id, final Offset offset) {
    newMemeTextOffsetSubject.add(MemeTextOffset(id: id, offset: offset));
  }

  void _changeMemeTextOffsetInternal(final MemeTextOffset newMemeTextOffset) {
    final copiedMemeTextOffsets = [...memeTextOffsetsSubject.value];
    final currentMemeTextOffset =
        copiedMemeTextOffsets.firstWhereOrNull((element) => element.id == newMemeTextOffset.id);
    if (currentMemeTextOffset != null) {
      copiedMemeTextOffsets.remove(currentMemeTextOffset);
    }
    copiedMemeTextOffsets.add(newMemeTextOffset);
    memeTextOffsetsSubject.add(copiedMemeTextOffsets);
    print('got new offset: $newMemeTextOffset');
  }

  void addNewText() {
    final newMemeText = MemeText.create();
    memeTextsSubject.add([...memeTextsSubject.value, newMemeText]);
    selectedMemeTextSubject.add(newMemeText);
  }

  void changeMemeText(final String id, final String text) {
    final copiedList = [...memeTextsSubject.value];
    final index = copiedList.indexWhere((element) => element.id == id);
    if (index == -1) {
      return;
    }
    copiedList.removeAt(index);
    copiedList.insert(index, MemeText(id: id, text: text));
    memeTextsSubject.add(copiedList);
  }

  void selectMemeText(final String id) {
    final foundMemeText = memeTextsSubject.value.firstWhereOrNull((element) => element.id == id);
    selectedMemeTextSubject.add(foundMemeText);
  }

  void deselectMemeText() {
    selectedMemeTextSubject.add(null);
  }

  Stream<List<MemeText>> observeMemeTexts() =>
      memeTextsSubject.distinct((prev, next) => ListEquality().equals(prev, next));

  Stream<MemeText?> observeSelectedMemeText() => selectedMemeTextSubject.distinct();

  void dispose() {
    memeTextsSubject.close();
    selectedMemeTextSubject.close();
    memeTextOffsetsSubject.close();
    newMemeTextOffsetSubject.close();
    newMemeTextSubscription?.cancel();
  }
}
