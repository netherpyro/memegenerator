import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/data/repositories/memes_repository.dart';

class MainBloc {

  Stream<List<Meme>> observeMemes() =>
      MemesRepository.getInstance().observeMemes();

  void dispose() {

  }
}