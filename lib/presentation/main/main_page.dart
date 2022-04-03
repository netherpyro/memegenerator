import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_page.dart';
import 'package:memogenerator/presentation/easter_egg/easter_egg_page.dart';
import 'package:memogenerator/presentation/main/main_bloc.dart';
import 'package:memogenerator/presentation/main/memes_with_docs_path.dart';
import 'package:memogenerator/presentation/main/models/template_full.dart';
import 'package:memogenerator/presentation/widgets/app_button.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late MainBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = MainBloc();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: WillPopScope(
        onWillPop: () async {
          return await showConfirmationExitDialog(context) ?? false;
        },
        child: DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: AppColors.lemon,
              foregroundColor: AppColors.darkGrey,
              title: GestureDetector(
                  onLongPress: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => EasterEggPage()),
                    );
                  },
                  child: Text("Мемогенератор", style: GoogleFonts.seymourOne(fontSize: 24))),
              bottom: TabBar(
                labelColor: AppColors.darkGrey,
                indicatorColor: AppColors.fuchsia,
                indicatorWeight: 3,
                tabs: [
                  Tab(text: "Созданные".toUpperCase()),
                  Tab(text: "Шаблоны".toUpperCase()),
                ],
              ),
            ),
            floatingActionButton: CreateMemeFab(),
            backgroundColor: Colors.white,
            body: TabBarView(
              children: [
                SafeArea(child: CreatedMemesGrid()),
                SafeArea(child: TemplatesGrid()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> showConfirmationExitDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Точно хотите выйти?"),
            content: Text("Мемы сами себя не сделают"),
            actionsPadding: EdgeInsets.symmetric(horizontal: 16),
            actions: [
              AppButton(
                onTap: () => Navigator.of(context).pop(false),
                text: "Остаться",
                color: AppColors.darkGrey,
              ),
              AppButton(
                onTap: () => Navigator.of(context).pop(true),
                text: "Выйти",
              ),
            ],
          );
        });
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}

class CreateMemeFab extends StatelessWidget {
  const CreateMemeFab({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return FloatingActionButton.extended(
      onPressed: () async {
        final selectedMemePath = await bloc.selectMeme();
        if (selectedMemePath == null) return;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CreateMemePage(selectedMemePath: selectedMemePath),
          ),
        );
      },
      backgroundColor: AppColors.fuchsia,
      icon: Icon(Icons.add, color: Colors.white),
      label: Text("Создать"),
    );
  }
}

class CreatedMemesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return StreamBuilder<MemesWithDocsPath>(
        stream: bloc.observeMemesWithDocsPath(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }
          final items = snapshot.requireData.memes;
          final docsPath = snapshot.requireData.docsPath;
          return GridView.extent(
            maxCrossAxisExtent: 180,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            children: items.map(
              (item) {
                return MemeGridItem(docsPath: docsPath, meme: item);
              },
            ).toList(),
          );
        });
  }
}

class MemeGridItem extends StatelessWidget {
  const MemeGridItem({
    Key? key,
    required this.docsPath,
    required this.meme,
  }) : super(key: key);

  final String docsPath;
  final Meme meme;

  @override
  Widget build(BuildContext context) {
    final imageFile = File("$docsPath${Platform.pathSeparator}${meme.id}.png");
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => CreateMemePage(id: meme.id)),
          );
        },
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.darkGrey, width: 1),
              ),
              alignment: Alignment.centerLeft,
              child: imageFile.existsSync() ? Image.file(imageFile) : Text(meme.id),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: DeleteButton(onDeleteAction: () => bloc.deleteMeme(meme.id), itemName: "мем"),
            )
          ],
        ));
  }
}

class DeleteButton extends StatelessWidget {
  final VoidCallback onDeleteAction;
  final String itemName;

  const DeleteButton({
    Key? key,
    required this.itemName,
    required this.onDeleteAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final delete = await showConfirmationDeleteDialog(context) ?? false;
        if (delete) {
          onDeleteAction();
        }
      },
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.darkGrey38,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.delete_outline, size: 24, color: Colors.white),
      ),
    );
  }

  Future<bool?> showConfirmationDeleteDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Удалить $itemName?"),
            content: Text("Выбранный $itemName будет удалён навсегда"),
            actionsPadding: EdgeInsets.symmetric(horizontal: 16),
            actions: [
              AppButton(
                onTap: () => Navigator.of(context).pop(false),
                text: "Отмена",
                color: AppColors.darkGrey,
              ),
              AppButton(
                onTap: () => Navigator.of(context).pop(true),
                text: "Удалить",
              ),
            ],
          );
        });
  }
}

class TemplatesGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return StreamBuilder<List<TemplateFull>>(
        stream: bloc.observeTemplates(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }
          final templates = snapshot.requireData;
          return GridView.extent(
            maxCrossAxisExtent: 180,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            children: templates.map((template) => TemplateGridItem(template: template)).toList(),
          );
        });
  }
}

class TemplateGridItem extends StatelessWidget {
  const TemplateGridItem({
    Key? key,
    required this.template,
  }) : super(key: key);

  final TemplateFull template;

  @override
  Widget build(BuildContext context) {
    final imageFile = File(template.fullImagePath);
    final bloc = Provider.of<MainBloc>(context, listen: false);
    return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CreateMemePage(selectedMemePath: template.fullImagePath),
            ),
          );
        },
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.darkGrey, width: 1),
              ),
              alignment: Alignment.centerLeft,
              child: imageFile.existsSync() ? Image.file(imageFile) : Text(template.id),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: DeleteButton(
                onDeleteAction: () => bloc.deleteTemplate(template.id),
                itemName: "шаблон",
              ),
            )
          ],
        ));
  }
}
