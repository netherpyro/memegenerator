import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_bloc.dart';
import 'package:memogenerator/presentation/create_meme/font_settings_bottom_sheet.dart';
import 'package:memogenerator/presentation/create_meme/meme_text_on_canvas.dart';
import 'package:memogenerator/presentation/widgets/app_button.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:stream_transform/stream_transform.dart';

import 'models/meme_text.dart';
import 'models/meme_text_with_offset.dart';
import 'models/meme_text_with_selection.dart';

class CreateMemePage extends StatefulWidget {
  final String? id;
  final String? selectedMemePath;

  CreateMemePage({Key? key, this.id, this.selectedMemePath}) : super(key: key);

  @override
  _CreateMemeState createState() => _CreateMemeState();
}

class _CreateMemeState extends State<CreateMemePage> {
  late CreateMemeBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = CreateMemeBloc(id: widget.id, selectedMemePath: widget.selectedMemePath);
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: WillPopScope(
        onWillPop: () async {
          final goBack = await showConfirmationExitDialog(context);
          return goBack ?? false;
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: AppColors.lemon,
            foregroundColor: AppColors.darkGrey,
            title: Text("Создаем мем"),
            bottom: EditTextBar(),
            actions: [
              GestureDetector(
                onTap: () => bloc.shareMeme(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Icons.share,
                    color: AppColors.darkGrey,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => bloc.saveMeme(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(
                    Icons.save,
                    color: AppColors.darkGrey,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          body: SafeArea(
            child: CreateMemePageContent(),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }

  Future<bool?> showConfirmationExitDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Хотите выйти?"),
            content: Text("Вы потеряете несохраненные изменения"),
            actionsPadding: EdgeInsets.symmetric(horizontal: 16),
            actions: [
              AppButton(
                onTap: () => Navigator.of(context).pop(false),
                text: "Отмена",
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
}

class EditTextBar extends StatefulWidget implements PreferredSizeWidget {
  const EditTextBar({Key? key}) : super(key: key);

  @override
  State<EditTextBar> createState() => _EditTextBarState();

  @override
  Size get preferredSize => Size.fromHeight(68);
}

class _EditTextBarState extends State<EditTextBar> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: StreamBuilder<MemeText?>(
            stream: bloc.observeSelectedMemeText(),
            builder: (context, snapshot) {
              final MemeText? selectedMemeText = snapshot.data;
              if (selectedMemeText?.text != controller.text) {
                final newText = selectedMemeText?.text ?? "";
                controller.text = newText;
                controller.selection = TextSelection.collapsed(offset: newText.length);
              }
              final hasSelectedText = selectedMemeText != null;
              return TextField(
                enabled: hasSelectedText,
                controller: controller,
                onChanged: (text) {
                  if (hasSelectedText) {
                    bloc.changeMemeText(selectedMemeText!.id, text);
                  }
                },
                onEditingComplete: () => bloc.deselectMemeText(),
                cursorColor: AppColors.fuchsia,
                decoration: InputDecoration(
                  hintText: hasSelectedText ? "Ввести текст" : "",
                  hintStyle: TextStyle(fontSize: 16, color: AppColors.darkGrey38),
                  filled: true,
                  fillColor: hasSelectedText ? AppColors.fuchsia16 : AppColors.darkGrey6,
                  focusColor: AppColors.fuchsia16,
                  disabledBorder:
                      UnderlineInputBorder(borderSide: BorderSide(color: AppColors.darkGrey38)),
                  enabledBorder:
                      UnderlineInputBorder(borderSide: BorderSide(color: AppColors.fuchsia38)),
                  focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.fuchsia, width: 2)),
                ),
              );
            }));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

class CreateMemePageContent extends StatefulWidget {
  @override
  _CreateMemePageContentState createState() => _CreateMemePageContentState();
}

class _CreateMemePageContentState extends State<CreateMemePageContent> {
  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Column(
      children: [
        Expanded(flex: 2, child: MemeCanvasWidget()),
        Container(
          height: 1,
          width: double.infinity,
          color: AppColors.darkGrey,
        ),
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.amber[50],
            child: StreamBuilder<MemeTextWithSelection>(
                stream: bloc.observeMemeTexts().combineLatest(
                      bloc.observeSelectedMemeText(),
                      (p0, p1) => MemeTextWithSelection(p0, p1 as MemeText?),
                    ),
                initialData: MemeTextWithSelection.emptyObject(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final MemeTextWithSelection mco = snapshot.data!;
                    return ListView.separated(
                      itemCount: 2 + mco.memeTexts.length,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return const SizedBox(height: 16);
                        } else if (index == 1) {
                          return Center(
                            child: AppButton(
                              onTap: () => bloc.addNewText(),
                              text: "Добавить текст",
                              icon: Icons.add,
                            ),
                          );
                        } else {
                          final memeText = mco.memeTexts[index - 2];
                          return BottomMemeText(mco: mco, memeText: memeText);
                        }
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        if (index > 1) {
                          return Container(
                              height: 1,
                              color: AppColors.darkGrey,
                              margin: const EdgeInsets.only(left: 16));
                        } else
                          return SizedBox.shrink();
                      },
                    );
                  } else
                    return SizedBox.shrink();
                }),
          ),
        ),
      ],
    );
  }
}

class BottomMemeText extends StatelessWidget {
  const BottomMemeText({
    Key? key,
    required this.mco,
    required this.memeText,
  }) : super(key: key);

  final MemeTextWithSelection mco;
  final MemeText memeText;

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return GestureDetector(
      onTap: () => bloc.selectMemeText(memeText.id),
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 48,
        color: mco.matchesId(memeText.id) ? AppColors.darkGrey16 : null,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Text(memeText.text,
                  style: GoogleFonts.roboto(
                      fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.darkGrey)),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    return Provider.value(
                      value: bloc,
                      child: FontSettingsBottomSheet(memeText: memeText),
                    );
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.font_download_outlined),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class MemeCanvasWidget extends StatelessWidget {
  const MemeCanvasWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return Container(
      color: AppColors.darkGrey38,
      padding: const EdgeInsets.all(8),
      alignment: Alignment.topCenter,
      child: AspectRatio(
        aspectRatio: 1,
        child: GestureDetector(
          onTap: () => bloc.deselectMemeText(),
          child: StreamBuilder<ScreenshotController>(
            stream: bloc.observeScreenshotController(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              return Screenshot(
                controller: snapshot.requireData,
                child: Stack(
                  children: [
                    BackgroundImage(),
                    MemeTexts(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class MemeTexts extends StatelessWidget {
  const MemeTexts({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return StreamBuilder<List<MemeTextWithOffset>>(
        stream: bloc.observeMemeTextWithOffsets(),
        initialData: const <MemeTextWithOffset>[],
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final memeTextWithOffset =
                snapshot.hasData ? snapshot.data! : const <MemeTextWithOffset>[];
            return LayoutBuilder(builder: (context, constraints) {
              return Stack(
                  children: memeTextWithOffset.map((memeTextWithOffset) {
                return DraggableMemeText(
                    key: ValueKey(memeTextWithOffset.memeText.id),
                    memeTextWithOffset: memeTextWithOffset,
                    parentConstraints: constraints);
              }).toList());
            });
          } else
            return SizedBox.shrink();
        });
  }
}

class BackgroundImage extends StatelessWidget {
  const BackgroundImage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return StreamBuilder<String?>(
        stream: bloc.observeMemePath(),
        builder: (context, snapshot) {
          final path = snapshot.hasData ? snapshot.data : null;
          if (path == null) {
            return Container(color: Colors.white);
          }
          return Image.file(File(path));
        });
  }
}

class DraggableMemeText extends StatefulWidget {
  final MemeTextWithOffset memeTextWithOffset;
  final BoxConstraints parentConstraints;

  const DraggableMemeText({
    Key? key,
    required this.memeTextWithOffset,
    required this.parentConstraints,
  }) : super(key: key);

  @override
  State<DraggableMemeText> createState() => _DraggableMemeTextState();
}

class _DraggableMemeTextState extends State<DraggableMemeText> {
  late double top;
  late double left;
  final double padding = 8;

  @override
  void initState() {
    super.initState();
    top = widget.memeTextWithOffset.offset?.dy ?? widget.parentConstraints.maxHeight / 2;
    left = widget.memeTextWithOffset.offset?.dx ?? widget.parentConstraints.maxWidth / 3;

    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
      bloc.onChangeTextOffset(widget.memeTextWithOffset.memeText.id, Offset(left, top));
    });
  }

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);

    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => bloc.selectMemeText(widget.memeTextWithOffset.memeText.id),
          onPanDown: (_) => bloc.selectMemeText(widget.memeTextWithOffset.memeText.id),
          onPanUpdate: (details) {
            setState(() {
              left = calculateLeft(details);
              top = calculateTop(details);
            });
          },
          onPanEnd: (details) =>
              bloc.onChangeTextOffset(widget.memeTextWithOffset.memeText.id, Offset(left, top)),
          child: StreamBuilder<MemeText?>(
              stream: bloc.observeSelectedMemeText(),
              builder: (context, snapshot) {
                final selectedItem = snapshot.hasData ? snapshot.data : null;
                final selected = widget.memeTextWithOffset.memeText.id == selectedItem?.id;
                return MemeTextOnCanvas(
                  padding: padding,
                  selected: selected,
                  parentConstraints: widget.parentConstraints,
                  text: widget.memeTextWithOffset.memeText.text,
                  fontSize: widget.memeTextWithOffset.memeText.fontSize,
                  color: widget.memeTextWithOffset.memeText.color,
                );
              })),
    );
  }

  double calculateLeft(DragUpdateDetails details) {
    final rawLeft = left + details.delta.dx;
    if (rawLeft < 0) {
      return 0;
    }
    if (rawLeft > widget.parentConstraints.maxWidth - 2 * padding - 10) {
      return widget.parentConstraints.maxWidth - 2 * padding - 10;
    }
    return rawLeft;
  }

  double calculateTop(DragUpdateDetails details) {
    final raw = top + details.delta.dy;
    if (raw < 0) {
      return 0;
    }
    if (raw > widget.parentConstraints.maxHeight - 2 * padding - 30) {
      return widget.parentConstraints.maxHeight - 2 * padding - 30;
    }
    return raw;
  }
}
