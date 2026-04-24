import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/join_request.dart';

part 'join_request_model.freezed.dart';
part 'join_request_model.g.dart';

@freezed
abstract class JoinRequestModel with _$JoinRequestModel {
  const factory JoinRequestModel({
    @JsonKey(name: '\$id') required String id,
    required String matchId,
    required String requesterUid,
    required String requesterPosition,
    String? requesterMessage,
    required String status,
    String? assignedSide,
    required DateTime createdAt,
    DateTime? respondedAt,
  }) = _JoinRequestModel;

  factory JoinRequestModel.fromJson(Map<String, dynamic> json) =>
      _$JoinRequestModelFromJson(json);
}

extension JoinRequestModelX on JoinRequestModel {
  JoinRequest toEntity() => JoinRequest(
        id: id,
        matchId: matchId,
        requesterUid: requesterUid,
        requesterPosition: requesterPosition,
        requesterMessage: requesterMessage,
        status: JoinRequestStatusX.fromString(status),
        assignedSide: AssignedSideX.fromString(assignedSide),
        createdAt: createdAt,
        respondedAt: respondedAt,
      );
}

extension JoinRequestModelFromEntity on JoinRequest {
  Map<String, dynamic> toModelJson() => {
        'matchId': matchId,
        'requesterUid': requesterUid,
        'requesterPosition': requesterPosition,
        'requesterMessage': requesterMessage,
        'status': status.value,
        'assignedSide': assignedSide?.value,
        'createdAt': createdAt.toIso8601String(),
        'respondedAt': respondedAt?.toIso8601String(),
      };
}
