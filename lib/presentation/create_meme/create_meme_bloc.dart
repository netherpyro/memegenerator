import 'dart:async';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/position.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_offset.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import 'models/meme_text.dart';
import 'models/meme_text_offset.dart';

class CreateMemeBloc {
  final memeTextsSubject = BehaviorSubject<List<MemeText>>.seeded(<MemeText>[]);
  final selectedMemeTextSubject = BehaviorSubject<MemeText?>.seeded(null);
  final memeTextOffsetsSubject = BehaviorSubject<List<MemeTextOffset>>.seeded(<MemeTextOffset>[]);
  StreamSubscription<bool>? saveMemeSubscription;
  StreamSubscription<Meme?>? existentMemeSubscription;

  final String id;

  CreateMemeBloc({required String? id}) : this.id = id ?? Uuid().v4() {
    // if (id == null) return;
    existentMemeSubscription = MemesRepository.getInstance().getMeme(this.id).asStream().listen(
      (meme) {
        if (meme == null) return;
        final memeTexts = meme.texts
            .map((textWithPosition) =>
                MemeText(id: textWithPosition.id, text: textWithPosition.text))
            .toList();
        final memeTextOffsets = meme.texts
            .map(
              (textWithPosition) => MemeTextOffset(
                id: textWithPosition.id,
                offset: Offset(
                  textWithPosition.position.left,
                  textWithPosition.position.top,
                ),
              ),
            )
            .toList();
        memeTextsSubject.add(memeTexts);
        memeTextOffsetsSubject.add(memeTextOffsets);
      },
      onError: (e, st) => print("Error in existentMemeSubscription: $e, $st"),
    );
  }

  void saveMeme() {
    final memeTexts = memeTextsSubject.value;
    final memeTextOffsets = memeTextOffsetsSubject.value;
    final textsWithPositions = memeTexts.map((memeText) {
      final memeTextPosition = memeTextOffsets
          .firstWhereOrNull((memeTextWithOffset) => memeTextWithOffset.id == memeText.id);
      final position = Position(
        left: memeTextPosition?.offset.dx ?? 0,
        top: memeTextPosition?.offset.dy ?? 0,
      );
      return TextWithPosition(id: memeText.id, text: memeText.text, position: position);
    }).toList();
    final meme = Meme(id: id, texts: textsWithPositions);

    saveMemeSubscription =
        MemesRepository.getInstance().addToMemes(meme).asStream().listen((saved) {
      print("Meme saved: $saved");
    }, onError: (e, st) => print("Error in saveMemeSubscription: $e, $st"));
  }

  void onChangeTextOffset(final String id, final Offset offset) {
    final copiedMemeTextOffsets = [...memeTextOffsetsSubject.value];
    final currentMemeTextOffset =
        copiedMemeTextOffsets.firstWhereOrNull((element) => element.id == id);
    if (currentMemeTextOffset != null) {
      copiedMemeTextOffsets.remove(currentMemeTextOffset);
    }
    copiedMemeTextOffsets.add(MemeTextOffset(id: id, offset: offset));
    memeTextOffsetsSubject.add(copiedMemeTextOffsets);
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

  Stream<List<MemeTextWithOffset>> observeMemeTextWithOffsets() {
    return Rx.combineLatest2<List<MemeText>, List<MemeTextOffset>, List<MemeTextWithOffset>>(
        observeMemeTexts(), memeTextOffsetsSubject.distinct(), (memeTexts, memeTextOffsets) {
      return memeTexts.map((memeText) {
        final memeTextOffset = memeTextOffsets.firstWhereOrNull((element) {
          return element.id == memeText.id;
        });
        return MemeTextWithOffset(
          id: memeText.id,
          text: memeText.text,
          offset: memeTextOffset?.offset,
        );
      }).toList();
    }).distinct((prev, next) => ListEquality().equals(prev, next));
  }

  Stream<MemeText?> observeSelectedMemeText() => selectedMemeTextSubject.distinct();

  void dispose() {
    memeTextsSubject.close();
    selectedMemeTextSubject.close();
    memeTextOffsetsSubject.close();
    saveMemeSubscription?.cancel();
    existentMemeSubscription?.cancel();
  }
}
