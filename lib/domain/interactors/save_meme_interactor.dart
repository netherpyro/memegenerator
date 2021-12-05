import 'dart:io';

import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/models/text_with_position.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';
import 'package:path_provider/path_provider.dart';

class SaveMemeInteractor {
  static SaveMemeInteractor? _instance;

  factory SaveMemeInteractor.getInstance() => _instance ??= SaveMemeInteractor._internal();

  SaveMemeInteractor._internal();

  Future<bool> saveMeme({
    required String id,
    required List<TextWithPosition> textWithPositions,
    String? imagePath,
  }) async {
    if (imagePath == null) {
      final meme = Meme(id: id, texts: textWithPositions);
      return MemesRepository.getInstance().addToMemes(meme);
    }

    final docsPath = await getApplicationDocumentsDirectory();
    final slash = Platform.pathSeparator;
    final memePath = "${docsPath.absolute.path}${slash}memes";
    await Directory(memePath).create(recursive: true);
    final imageName = imagePath.split(slash).last;
    final newImagePath = "$memePath$slash$imageName";
    final tempFile = File(imagePath);
    await tempFile.copy(newImagePath);
    final meme = Meme(
      id: id,
      texts: textWithPositions,
      memePath: newImagePath,
    );

    return MemesRepository.getInstance().addToMemes(meme);
  }
}
