import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/discovery_block.dart';

part 'discovery_block_model.freezed.dart';
part 'discovery_block_model.g.dart';

@freezed
abstract class DiscoveryBlockModel with _$DiscoveryBlockModel {
  const factory DiscoveryBlockModel({
    @JsonKey(name: '\$id') required String id,
    required String creatorUid,
    required String playerUid,
    required DateTime createdAt,
  }) = _DiscoveryBlockModel;

  factory DiscoveryBlockModel.fromJson(Map<String, dynamic> json) =>
      _$DiscoveryBlockModelFromJson(json);
}

extension DiscoveryBlockModelX on DiscoveryBlockModel {
  DiscoveryBlock toEntity() => DiscoveryBlock(
        id: id,
        creatorUid: creatorUid,
        playerUid: playerUid,
        createdAt: createdAt,
      );
}
