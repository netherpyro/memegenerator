import 'package:memogenerator/data/models/template.dart';
import 'package:memogenerator/data/repositories/templates_repository.dart';
import 'package:memogenerator/domain/interactors/copy_unique_file_interactor.dart';
import 'package:uuid/uuid.dart';

class SaveTemplateInteractor {
  static const templatesPathName = "templates";
  static SaveTemplateInteractor? _instance;

  factory SaveTemplateInteractor.getInstance() => _instance ??= SaveTemplateInteractor._internal();

  SaveTemplateInteractor._internal();

  Future<bool> saveTemplate({
    required String imagePath,
  }) async {
    final newImagePath = await CopyUniqueFileInteractor.getInstance()
        .copyUniqueFile(directoryWithFiles: templatesPathName, filePath: imagePath);
    final template = Template(
      id: Uuid().v4(),
      imageUrl: newImagePath,
    );

    return TemplatesRepository.getInstance().addItemOrReplaceById(template);
  }
}
