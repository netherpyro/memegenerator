import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:memogenerator/presentation/create_meme/create_meme_bloc.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:stream_transform/stream_transform.dart';

import 'models/meme_text.dart';
import 'models/meme_text_with_selection.dart';

class CreateMemePage extends StatefulWidget {
  CreateMemePage({Key? key}) : super(key: key);

  @override
  _CreateMemeState createState() => _CreateMemeState();
}

class _CreateMemeState extends State<CreateMemePage> {
  late CreateMemeBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = CreateMemeBloc();
  }

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: AppColors.lemon,
          foregroundColor: AppColors.darkGrey,
          title: Text("Создаем мем"),
          bottom: EditTextBar(),
        ),
        backgroundColor: Colors.white,
        body: SafeArea(
          child: CreateMemePageContent(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
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
            child: StreamBuilder<MemeCanvasObject>(
                stream: bloc.observeMemeTexts().combineLatest(
                      bloc.observeSelectedMemeText(),
                      (p0, p1) => MemeCanvasObject(p0, p1 as MemeText?),
                    ),
                initialData: MemeCanvasObject.emptyObject(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final MemeCanvasObject mco = snapshot.data!;
                    return ListView.separated(
                      itemCount: 2 + mco.memeTexts.length,
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return const SizedBox(height: 12);
                        } else if (index == 1) {
                          return const AddNewMemeTextButton();
                        } else {
                          final memeText = mco.memeTexts[index - 2];
                          return Container(
                            height: 48,
                            color: mco.matchesId(memeText.id) ? AppColors.darkGrey16 : null,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(memeText.text,
                                style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.darkGrey)),
                          );
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
      child: GestureDetector(
        onTap: () => bloc.deselectMemeText(),
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            color: Colors.white,
            child: StreamBuilder<MemeCanvasObject>(
                initialData: MemeCanvasObject.emptyObject(),
                stream: bloc.observeMemeTexts().combineLatest(
                      bloc.observeSelectedMemeText(),
                      (p0, p1) => MemeCanvasObject(p0, p1 as MemeText?),
                    ),
                builder: (context, snapshot) {
                  final MemeCanvasObject mco = snapshot.data!;
                  return LayoutBuilder(builder: (context, constraints) {
                    return Stack(
                      children: mco.memeTexts
                          .map((e) => DraggableMemeText(
                                memeText: e,
                                parentConstraints: constraints,
                                selected: mco.matchesId(e.id),
                              ))
                          .toList(),
                    );
                  });
                }),
          ),
        ),
      ),
    );
  }
}

class DraggableMemeText extends StatefulWidget {
  final MemeText memeText;
  final BoxConstraints parentConstraints;
  final bool selected;

  const DraggableMemeText({
    Key? key,
    required this.memeText,
    required this.parentConstraints,
    required this.selected,
  }) : super(key: key);

  @override
  State<DraggableMemeText> createState() => _DraggableMemeTextState();
}

class _DraggableMemeTextState extends State<DraggableMemeText> {
  double top = -1;
  double left = -1;
  final double padding = 8;

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    top = top == -1 ? widget.parentConstraints.maxHeight / 2 : top;
    left = left == -1 ? widget.parentConstraints.maxWidth / 3 : left;

    return Positioned(
      top: top,
      left: left,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => bloc.selectMemeText(widget.memeText.id),
        onPanDown: (_) => bloc.selectMemeText(widget.memeText.id),
        onPanUpdate: (details) {
          setState(() {
            left = calculateLeft(details);
            top = calculateTop(details);
          });
        },
        child: Container(
          decoration: widget.selected
              ? BoxDecoration(
                  color: AppColors.darkGrey16,
                  border: Border.fromBorderSide(
                    BorderSide(
                      color: AppColors.fuchsia,
                    ),
                  ),
                )
              : null,
          constraints: BoxConstraints(
            maxWidth: widget.parentConstraints.maxWidth,
            maxHeight: widget.parentConstraints.maxHeight,
          ),
          padding: EdgeInsets.all(padding),
          child: Text(
            widget.memeText.text,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black, fontSize: 24),
          ),
        ),
      ),
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

class AddNewMemeTextButton extends StatelessWidget {
  const AddNewMemeTextButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => bloc.addNewText(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: AppColors.fuchsia),
              const SizedBox(width: 8),
              Text("Добавить текст".toUpperCase(),
                  style: TextStyle(
                    color: AppColors.fuchsia,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
