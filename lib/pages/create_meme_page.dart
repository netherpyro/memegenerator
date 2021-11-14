import 'package:flutter/material.dart';
import 'package:memogenerator/blocs/create_meme_bloc.dart';
import 'package:memogenerator/resources/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:stream_transform/stream_transform.dart';

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
                controller.selection =
                    TextSelection.collapsed(offset: newText.length);
              }
              return TextField(
                enabled: selectedMemeText != null,
                controller: controller,
                onChanged: (text) {
                  if (selectedMemeText != null) {
                    bloc.changeMemeText(selectedMemeText.id, text);
                  }
                },
                onEditingComplete: () => bloc.deselectMemeText(),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.darkGrey6,
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
            color: Colors.white,
            child: ListView(
              children: [
                const SizedBox(height: 12),
                const AddNewMemeTextButton(),
              ],
            ),
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
                  final MemeCanvasObject mco = snapshot.hasData
                      ? snapshot.data!
                      : MemeCanvasObject.emptyObject();
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

class MemeCanvasObject {
  late List<MemeText> memeTexts;
  late MemeText? selectedText;

  MemeCanvasObject(List<MemeText> memeTexts, MemeText? selectedMemeText) {
    this.memeTexts = memeTexts;
    this.selectedText = selectedMemeText;
  }

  factory MemeCanvasObject.emptyObject() {
    return MemeCanvasObject(const <MemeText>[], null);
  }

  bool matchesId(String? id) {
    return selectedText?.id == id;
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
  double top = 0;
  double left = 0;
  final double padding = 8;

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<CreateMemeBloc>(context, listen: false);
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
