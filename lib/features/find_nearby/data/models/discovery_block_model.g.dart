// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_block_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DiscoveryBlockModel _$DiscoveryBlockModelFromJson(Map<String, dynamic> json) =>
    _DiscoveryBlockModel(
      id: json[r'$id'] as String,
      creatorUid: json['creatorUid'] as String,
      playerUid: json['playerUid'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$DiscoveryBlockModelToJson(
  _DiscoveryBlockModel instance,
) => <String, dynamic>{
  r'$id': instance.id,
  'creatorUid': instance.creatorUid,
  'playerUid': instance.playerUid,
  'createdAt': instance.createdAt.toIso8601String(),
};
