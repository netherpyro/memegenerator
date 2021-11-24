import 'package:equatable/equatable.dart';

import 'meme_text.dart';

class MemeCanvasObject extends Equatable {
  final List<MemeText> memeTexts;
  final MemeText? selectedText;

  MemeCanvasObject(this.memeTexts, this.selectedText);

  factory MemeCanvasObject.emptyObject() {
    return MemeCanvasObject(const <MemeText>[], null);
  }

  bool matchesId(String? id) {
    return selectedText?.id == id;
  }

  @override
  List<Object?> get props => [memeTexts, selectedText];
}
