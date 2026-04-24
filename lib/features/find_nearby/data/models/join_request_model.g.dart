// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_JoinRequestModel _$JoinRequestModelFromJson(Map<String, dynamic> json) =>
    _JoinRequestModel(
      id: json[r'$id'] as String,
      matchId: json['matchId'] as String,
      requesterUid: json['requesterUid'] as String,
      requesterPosition: json['requesterPosition'] as String,
      requesterMessage: json['requesterMessage'] as String?,
      status: json['status'] as String,
      assignedSide: json['assignedSide'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      respondedAt: json['respondedAt'] == null
          ? null
          : DateTime.parse(json['respondedAt'] as String),
    );

Map<String, dynamic> _$JoinRequestModelToJson(_JoinRequestModel instance) =>
    <String, dynamic>{
      r'$id': instance.id,
      'matchId': instance.matchId,
      'requesterUid': instance.requesterUid,
      'requesterPosition': instance.requesterPosition,
      'requesterMessage': instance.requesterMessage,
      'status': instance.status,
      'assignedSide': instance.assignedSide,
      'createdAt': instance.createdAt.toIso8601String(),
      'respondedAt': instance.respondedAt?.toIso8601String(),
    };
