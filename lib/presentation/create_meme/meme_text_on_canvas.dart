import 'package:flutter/material.dart';
import 'package:memogenerator/resources/app_colors.dart';

class MemeTextOnCanvas extends StatelessWidget {
  final double padding;
  final bool selected;
  final BoxConstraints parentConstraints;
  final String text;
  final double fontSize;
  final Color color;
  final FontWeight fontWeight;

  const MemeTextOnCanvas({
    Key? key,
    required this.padding,
    required this.selected,
    required this.parentConstraints,
    required this.text,
    required this.fontSize,
    required this.color,
    required this.fontWeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: parentConstraints.maxWidth,
        maxHeight: parentConstraints.maxHeight,
      ),
      padding: EdgeInsets.all(padding),
      decoration: selected
          ? BoxDecoration(
              color: AppColors.darkGrey16,
              border: Border.fromBorderSide(
                BorderSide(
                  color: AppColors.fuchsia,
                ),
              ),
            )
          : null,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }
}
