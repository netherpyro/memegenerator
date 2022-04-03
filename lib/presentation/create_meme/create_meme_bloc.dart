import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/position.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:memogenerator/domain/interactors/save_meme_interactor.dart';
import 'package:memogenerator/domain/interactors/screenshot_interactor.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text_with_offset.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:screenshot/screenshot.dart';
import 'package:uuid/uuid.dart';

import 'models/meme_text.dart';
import 'models/meme_text_offset.dart';

class CreateMemeBloc {
  final memeTextsSubject = BehaviorSubject<List<MemeText>>.seeded(<MemeText>[]);
  final selectedMemeTextSubject = BehaviorSubject<MemeText?>.seeded(null);
  final memeTextOffsetsSubject =
      BehaviorSubject<List<MemeTextOffset>>.seeded(<MemeTextOffset>[]);
  final memePathSubject = BehaviorSubject<String?>.seeded(null);
  final screenshotControllerSubject =
      BehaviorSubject<ScreenshotController>.seeded(ScreenshotController());

  StreamSubscription<bool>? saveMemeSubscription;
  StreamSubscription<Meme?>? existentMemeSubscription;
  StreamSubscription<void>? shareMemeSubscription;

  final String id;
  bool _hasChanges = false;

  CreateMemeBloc({
    final String? id,
    final String? selectedMemePath,
  }) : this.id = id ?? Uuid().v4() {
    final isNewMeme = id == null;
    _hasChanges = isNewMeme;
    if (!isNewMeme) _subscribeToExistentMeme();
    memePathSubject.add(selectedMemePath);
  }

  get hasChanges => _hasChanges;

  void shareMeme() {
    shareMemeSubscription?.cancel();
    shareMemeSubscription = ScreenshotInteractor.getInstance()
        .shareScreenshot(screenshotControllerSubject.value)
        .asStream()
        .listen(
          (event) {},
          onError: (e, st) => print("Error in shareMemeSubscription: $e, $st"),
        );
  }

  void changeFontSettings(
    final String textId,
    final Color color,
    final double fontSize,
    final FontWeight fontWeight,
  ) {
    _hasChanges = true;
    final copiedList = [...memeTextsSubject.value];
    final index = copiedList.indexWhere((element) => element.id == textId);
    if (index == -1) {
      return;
    }
    final oldMemeText = copiedList[index];
    copiedList.removeAt(index);
    copiedList.insert(
      index,
      oldMemeText.copyWithChangedFontSetting(color, fontSize, fontWeight),
    );
    memeTextsSubject.add(copiedList);
  }

  void saveMeme() {
    final memeTexts = memeTextsSubject.value;
    final memeTextOffsets = memeTextOffsetsSubject.value;
    final textsWithPositions = memeTexts.map((memeText) {
      final memeTextPosition = memeTextOffsets.firstWhereOrNull(
          (memeTextWithOffset) => memeTextWithOffset.id == memeText.id);
      final position = Position(
        left: memeTextPosition?.offset.dx ?? 0,
        top: memeTextPosition?.offset.dy ?? 0,
      );
      return TextWithPosition(
        id: memeText.id,
        text: memeText.text,
        position: position,
        fontSize: memeText.fontSize,
        color: memeText.color,
        fontWeight: memeText.fontWeight,
      );
    }).toList();

    saveMemeSubscription = SaveMemeInteractor.getInstance()
        .saveMeme(
          id: id,
          textWithPositions: textsWithPositions,
          screenshotController: screenshotControllerSubject.value,
          imagePath: memePathSubject.value,
        )
        .asStream()
        .listen((saved) {
      _hasChanges = false;
      print("Meme saved: $saved");
    }, onError: (e, st) => print("Error in saveMemeSubscription: $e, $st"));
  }

  void preSaveTextOffset(final String id, final Offset offset) {
    _changeTextOffsetInternal(id, offset);
  }

  void onChangeTextOffset(final String id, final Offset offset) {
    _hasChanges = true;
    _changeTextOffsetInternal(id, offset);
  }

  void _changeTextOffsetInternal(final String id, final Offset offset) {
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
    _hasChanges = true;
    final newMemeText = MemeText.create();
    memeTextsSubject.add([...memeTextsSubject.value, newMemeText]);
    selectedMemeTextSubject.add(newMemeText);
  }

  void changeMemeText(final String id, final String text) {
    _hasChanges = true;
    final copiedList = [...memeTextsSubject.value];
    final index = copiedList.indexWhere((element) => element.id == id);
    if (index == -1) {
      return;
    }
    final oldMemeText = copiedList[index];
    copiedList.removeAt(index);
    copiedList.insert(index, oldMemeText.copyWithChangedText(text));
    memeTextsSubject.add(copiedList);
  }

  void selectMemeText(final String id) {
    final foundMemeText =
        memeTextsSubject.value.firstWhereOrNull((element) => element.id == id);
    selectedMemeTextSubject.add(foundMemeText);
  }

  void deselectMemeText() {
    selectedMemeTextSubject.add(null);
  }

  void clickRemoveText(String textId) {
    _hasChanges = true;
    final copiedList = [...memeTextsSubject.value];
    copiedList.removeWhere((element) => element.id == textId);
    memeTextsSubject.add(copiedList);
    if (selectedMemeTextSubject.value?.id == textId) {
      selectedMemeTextSubject.add(null);
    }
  }

  Stream<List<MemeText>> observeMemeTexts() => memeTextsSubject
      .distinct((prev, next) => ListEquality().equals(prev, next));

  Stream<List<MemeTextWithOffset>> observeMemeTextWithOffsets() {
    return Rx.combineLatest2<List<MemeText>, List<MemeTextOffset>,
            List<MemeTextWithOffset>>(
        observeMemeTexts(), memeTextOffsetsSubject.distinct(),
        (memeTexts, memeTextOffsets) {
      return memeTexts.map((memeText) {
        final memeTextOffset = memeTextOffsets.firstWhereOrNull((element) {
          return element.id == memeText.id;
        });
        return MemeTextWithOffset(
          memeText: memeText,
          offset: memeTextOffset?.offset,
        );
      }).toList();
    }).distinct((prev, next) => ListEquality().equals(prev, next));
  }

  Stream<MemeText?> observeSelectedMemeText() =>
      selectedMemeTextSubject.distinct();

  Stream<String?> observeMemePath() => memePathSubject.distinct();

  Stream<ScreenshotController> observeScreenshotController() =>
      screenshotControllerSubject.distinct();

  void _subscribeToExistentMeme() {
    existentMemeSubscription =
        MemesRepository.getInstance().getItemById(this.id).asStream().listen(
      (meme) {
        if (meme == null) return;
        final memeTexts = meme.texts
            .map((textWithPosition) => MemeText.createFromTextWithPosition(textWithPosition))
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
        if (meme.memePath != null) {
          getApplicationDocumentsDirectory().then((docsDirectory) {
            final onlyImageName =
                meme.memePath!.split(Platform.pathSeparator).last;
            final fullImagePath =
                "${docsDirectory.absolute.path}${Platform.pathSeparator}${SaveMemeInteractor.memesPathName}${Platform.pathSeparator}$onlyImageName";
            memePathSubject.add(fullImagePath);
          });
        }
      },
      onError: (e, st) => print("Error in existentMemeSubscription: $e, $st"),
    );
  }

  void dispose() {
    memeTextsSubject.close();
    selectedMemeTextSubject.close();
    memeTextOffsetsSubject.close();
    memePathSubject.close();
    screenshotControllerSubject.close();

    saveMemeSubscription?.cancel();
    existentMemeSubscription?.cancel();
    shareMemeSubscription?.cancel();
  }
}
