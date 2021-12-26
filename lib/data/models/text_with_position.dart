import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:memogenerator/data/models/position.dart';

part 'text_with_position.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class TextWithPosition extends Equatable {
  final String id;
  final String text;
  final Position position;
  final double? fontSize;
  @JsonKey(toJson: colorToJson, fromJson: colorFromJson)
  final Color? color;
  @JsonKey(toJson: fontWeightToJson, fromJson: fontWeightFromJson)
  final FontWeight? fontWeight;

  TextWithPosition({
    required this.id,
    required this.text,
    required this.position,
    required this.fontSize,
    required this.color,
    required this.fontWeight,
  });

  factory TextWithPosition.fromJson(final Map<String, dynamic> json) =>
      _$TextWithPositionFromJson(json);

  Map<String, dynamic> toJson() => _$TextWithPositionToJson(this);

  @override
  List<Object?> get props => [id, text, position, fontSize, color, fontWeight];
}

String? colorToJson(final Color? color) {
  return color == null ? null : color.value.toRadixString(16);
}

Color? colorFromJson(final String? colorString) {
  if (colorString == null) return null;
  final intColor = int.tryParse(colorString, radix: 16);
  return intColor == null ? null : Color(intColor);
}

int? fontWeightToJson(final FontWeight? fontWeight) {
  return fontWeight == null ? null : fontWeight.index;
}

FontWeight? fontWeightFromJson(final int? fontWeightIndex) {
  if (fontWeightIndex == null) return null;
  return FontWeight.values
      .firstWhere((element) => element.index == fontWeightIndex);
}
