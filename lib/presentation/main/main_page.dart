import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memogenerator/data/models/meme.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_page.dart';
import 'package:memogenerator/presentation/main/main_bloc.dart';
import 'package:memogenerator/presentation/main/memes_with_docs_path.dart';
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
        child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: AppColors.lemon,
            foregroundColor: AppColors.darkGrey,
            title: Text("Мемогенератор",
                style: GoogleFonts.seymourOne(fontSize: 24)),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final selectedMemePath = await bloc.selectMeme();
              if (selectedMemePath == null) return;

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      CreateMemePage(selectedMemePath: selectedMemePath),
                ),
              );
            },
            backgroundColor: AppColors.fuchsia,
            icon: Icon(Icons.add, color: Colors.white),
            label: Text("Создать"),
          ),
          backgroundColor: Colors.white,
          body: SafeArea(
            child: MainPageContent(),
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

class MainPageContent extends StatefulWidget {
  @override
  _MainPageContentState createState() => _MainPageContentState();
}

class _MainPageContentState extends State<MainPageContent> {
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
                return GridItem(docsPath: docsPath, meme: item);
              },
            ).toList(),
          );
        });
  }
}

class GridItem extends StatelessWidget {
  const GridItem({
    Key? key,
    required this.docsPath,
    required this.meme,
  }) : super(key: key);

  final String docsPath;
  final Meme meme;

  @override
  Widget build(BuildContext context) {
    final imageFile = File("$docsPath${Platform.pathSeparator}${meme.id}.png");
    return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => CreateMemePage(id: meme.id)),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.darkGrey, width: 1),
          ),
          alignment: Alignment.centerLeft,
          child: imageFile.existsSync() ? Image.file(imageFile) : Text(meme.id),
        ));
  }
}
