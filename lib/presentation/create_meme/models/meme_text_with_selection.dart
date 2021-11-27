import 'package:equatable/equatable.dart';

import 'meme_text.dart';

class MemeTextWithSelection extends Equatable {
  final List<MemeText> memeTexts;
  final MemeText? selectedText;

  MemeTextWithSelection(this.memeTexts, this.selectedText);

  factory MemeTextWithSelection.emptyObject() {
    return MemeTextWithSelection(const <MemeText>[], null);
  }

  bool matchesId(String? id) {
    return selectedText?.id == id;
  }

  @override
  List<Object?> get props => [memeTexts, selectedText];
}
