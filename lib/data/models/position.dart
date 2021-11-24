import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'position.g.dart';

@JsonSerializable(fieldRename: FieldRename.kebab, explicitToJson: true)
class Position extends Equatable {
  final double left;
  final double top;

  Position({required this.left, required this.top});

  factory Position.fromJson(final Map<String, dynamic> json) =>
      _$positionFromJson(json);

  Map<String, dynamic> toJson() => _$positionToJson(this);

  @override
  List<Object?> get props => [left, top];
}
