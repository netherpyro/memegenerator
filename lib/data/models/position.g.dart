// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Position _$positionFromJson(Map<String, dynamic> json) => Position(
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
    );

Map<String, dynamic> _$positionToJson(Position instance) => <String, dynamic>{
      'left': instance.left,
      'top': instance.top,
    };