import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:memogenerator/presentation/create_meme/meme_text_on_canvas.dart';
import 'package:memogenerator/presentation/create_meme/models/meme_text.dart';
import 'package:memogenerator/presentation/widgets/app_button.dart';
import 'package:memogenerator/resources/app_colors.dart';

class FontSettingsBottomSheet extends StatefulWidget {
  final MemeText memeText;

  const FontSettingsBottomSheet({
    Key? key,
    required this.memeText,
  }) : super(key: key);

  @override
  State<FontSettingsBottomSheet> createState() => _FontSettingsBottomSheetState();
}

class _FontSettingsBottomSheetState extends State<FontSettingsBottomSheet> {
  double fontSize = 20;
  Color color = Colors.black;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Center(
              child: Container(
                  height: 4,
                  width: 64,
                  decoration: BoxDecoration(
                    color: AppColors.darkGrey38,
                    borderRadius: BorderRadius.circular(2),
                  ))),
          const SizedBox(height: 16),
          MemeTextOnCanvas(
            padding: 8,
            selected: true,
            parentConstraints: BoxConstraints.expand(),
            text: widget.memeText.text,
            fontSize: fontSize,
            color: color,
          ),
          const SizedBox(height: 48),
          FontSizeSlider(changeFontSize: (value) {
            setState(() => fontSize = value);
          }),
          const SizedBox(height: 16),
          ColorSelection(
            changeColor: (color) {
              setState(() => this.color = color);
            },
          ),
          const SizedBox(height: 36),
          Align(
            alignment: Alignment.centerRight,
            child: Buttons(),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class Buttons extends StatelessWidget {
  const Buttons({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          onTap: () {},
          text: "Отмена",
          color: AppColors.darkGrey,
        ),
        const SizedBox(width: 24),
        AppButton(
          onTap: () {},
          text: "Сохранить",
        ),
        const SizedBox(width: 16),
      ],
    );
  }
}

class ColorSelection extends StatelessWidget {
  const ColorSelection({
    Key? key,
    required this.changeColor,
  }) : super(key: key);

  final ValueChanged<Color> changeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const SizedBox(width: 16),
        Text(
          "Color:",
          style: TextStyle(
            fontSize: 20,
            color: AppColors.darkGrey,
          ),
        ),
        const SizedBox(width: 16),
        ColorSelectionBox(changeColor: changeColor, color: Colors.white),
        const SizedBox(width: 16),
        ColorSelectionBox(changeColor: changeColor, color: Colors.black),
        const SizedBox(width: 16),
      ],
    );
  }
}

class ColorSelectionBox extends StatelessWidget {
  final ValueChanged<Color> changeColor;
  final Color color;

  const ColorSelectionBox({
    Key? key,
    required this.changeColor,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => changeColor(color),
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.black, width: 1),
        ),
      ),
    );
  }
}

class FontSizeSlider extends StatefulWidget {
  const FontSizeSlider({
    Key? key,
    required this.changeFontSize,
  }) : super(key: key);

  final ValueChanged<double> changeFontSize;

  @override
  State<FontSizeSlider> createState() => _FontSizeSliderState();
}

class _FontSizeSliderState extends State<FontSizeSlider> {
  double fontSize = 20;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            "Size:",
            style: TextStyle(
              fontSize: 20,
              color: AppColors.darkGrey,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.fuchsia,
              inactiveTrackColor: AppColors.fuchsia38,
              valueIndicatorShape: PaddleSliderValueIndicatorShape(),
              thumbColor: AppColors.fuchsia,
              valueIndicatorColor: AppColors.fuchsia,
            ),
            child: Slider(
              min: 16,
              max: 32,
              label: fontSize.round().toString(),
              value: fontSize,
              onChanged: (value) {
                setState(() {
                  fontSize = value;
                  widget.changeFontSize(value);
                });
              },
            ),
          ),
        ),
      ],
    );
  }
}
