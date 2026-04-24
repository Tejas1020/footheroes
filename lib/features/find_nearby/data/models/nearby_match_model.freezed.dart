// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nearby_match_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NearbyMatchModel {

@JsonKey(name: '\$id') String get id; String? get venueId; String? get venueName; double? get latitude; double? get longitude; String? get geohashPrefix; String get format; DateTime get startTime; bool get openToNearby; int get slotsNeeded; int get slotsRemaining; String? get requiredPositions; DateTime? get requestsCloseAt; String get createdBy; double? get distanceKm;
/// Create a copy of NearbyMatchModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NearbyMatchModelCopyWith<NearbyMatchModel> get copyWith => _$NearbyMatchModelCopyWithImpl<NearbyMatchModel>(this as NearbyMatchModel, _$identity);

  /// Serializes this NearbyMatchModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NearbyMatchModel&&(identical(other.id, id) || other.id == id)&&(identical(other.venueId, venueId) || other.venueId == venueId)&&(identical(other.venueName, venueName) || other.venueName == venueName)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.geohashPrefix, geohashPrefix) || other.geohashPrefix == geohashPrefix)&&(identical(other.format, format) || other.format == format)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.openToNearby, openToNearby) || other.openToNearby == openToNearby)&&(identical(other.slotsNeeded, slotsNeeded) || other.slotsNeeded == slotsNeeded)&&(identical(other.slotsRemaining, slotsRemaining) || other.slotsRemaining == slotsRemaining)&&(identical(other.requiredPositions, requiredPositions) || other.requiredPositions == requiredPositions)&&(identical(other.requestsCloseAt, requestsCloseAt) || other.requestsCloseAt == requestsCloseAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,venueId,venueName,latitude,longitude,geohashPrefix,format,startTime,openToNearby,slotsNeeded,slotsRemaining,requiredPositions,requestsCloseAt,createdBy,distanceKm);

@override
String toString() {
  return 'NearbyMatchModel(id: $id, venueId: $venueId, venueName: $venueName, latitude: $latitude, longitude: $longitude, geohashPrefix: $geohashPrefix, format: $format, startTime: $startTime, openToNearby: $openToNearby, slotsNeeded: $slotsNeeded, slotsRemaining: $slotsRemaining, requiredPositions: $requiredPositions, requestsCloseAt: $requestsCloseAt, createdBy: $createdBy, distanceKm: $distanceKm)';
}


}

/// @nodoc
abstract mixin class $NearbyMatchModelCopyWith<$Res>  {
  factory $NearbyMatchModelCopyWith(NearbyMatchModel value, $Res Function(NearbyMatchModel) _then) = _$NearbyMatchModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '\$id') String id, String? venueId, String? venueName, double? latitude, double? longitude, String? geohashPrefix, String format, DateTime startTime, bool openToNearby, int slotsNeeded, int slotsRemaining, String? requiredPositions, DateTime? requestsCloseAt, String createdBy, double? distanceKm
});




}
/// @nodoc
class _$NearbyMatchModelCopyWithImpl<$Res>
    implements $NearbyMatchModelCopyWith<$Res> {
  _$NearbyMatchModelCopyWithImpl(this._self, this._then);

  final NearbyMatchModel _self;
  final $Res Function(NearbyMatchModel) _then;

/// Create a copy of NearbyMatchModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? venueId = freezed,Object? venueName = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? geohashPrefix = freezed,Object? format = null,Object? startTime = null,Object? openToNearby = null,Object? slotsNeeded = null,Object? slotsRemaining = null,Object? requiredPositions = freezed,Object? requestsCloseAt = freezed,Object? createdBy = null,Object? distanceKm = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,venueId: freezed == venueId ? _self.venueId : venueId // ignore: cast_nullable_to_non_nullable
as String?,venueName: freezed == venueName ? _self.venueName : venueName // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,geohashPrefix: freezed == geohashPrefix ? _self.geohashPrefix : geohashPrefix // ignore: cast_nullable_to_non_nullable
as String?,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,openToNearby: null == openToNearby ? _self.openToNearby : openToNearby // ignore: cast_nullable_to_non_nullable
as bool,slotsNeeded: null == slotsNeeded ? _self.slotsNeeded : slotsNeeded // ignore: cast_nullable_to_non_nullable
as int,slotsRemaining: null == slotsRemaining ? _self.slotsRemaining : slotsRemaining // ignore: cast_nullable_to_non_nullable
as int,requiredPositions: freezed == requiredPositions ? _self.requiredPositions : requiredPositions // ignore: cast_nullable_to_non_nullable
as String?,requestsCloseAt: freezed == requestsCloseAt ? _self.requestsCloseAt : requestsCloseAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [NearbyMatchModel].
extension NearbyMatchModelPatterns on NearbyMatchModel {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NearbyMatchModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NearbyMatchModel() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NearbyMatchModel value)  $default,){
final _that = this;
switch (_that) {
case _NearbyMatchModel():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NearbyMatchModel value)?  $default,){
final _that = this;
switch (_that) {
case _NearbyMatchModel() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '\$id')  String id,  String? venueId,  String? venueName,  double? latitude,  double? longitude,  String? geohashPrefix,  String format,  DateTime startTime,  bool openToNearby,  int slotsNeeded,  int slotsRemaining,  String? requiredPositions,  DateTime? requestsCloseAt,  String createdBy,  double? distanceKm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NearbyMatchModel() when $default != null:
return $default(_that.id,_that.venueId,_that.venueName,_that.latitude,_that.longitude,_that.geohashPrefix,_that.format,_that.startTime,_that.openToNearby,_that.slotsNeeded,_that.slotsRemaining,_that.requiredPositions,_that.requestsCloseAt,_that.createdBy,_that.distanceKm);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '\$id')  String id,  String? venueId,  String? venueName,  double? latitude,  double? longitude,  String? geohashPrefix,  String format,  DateTime startTime,  bool openToNearby,  int slotsNeeded,  int slotsRemaining,  String? requiredPositions,  DateTime? requestsCloseAt,  String createdBy,  double? distanceKm)  $default,) {final _that = this;
switch (_that) {
case _NearbyMatchModel():
return $default(_that.id,_that.venueId,_that.venueName,_that.latitude,_that.longitude,_that.geohashPrefix,_that.format,_that.startTime,_that.openToNearby,_that.slotsNeeded,_that.slotsRemaining,_that.requiredPositions,_that.requestsCloseAt,_that.createdBy,_that.distanceKm);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '\$id')  String id,  String? venueId,  String? venueName,  double? latitude,  double? longitude,  String? geohashPrefix,  String format,  DateTime startTime,  bool openToNearby,  int slotsNeeded,  int slotsRemaining,  String? requiredPositions,  DateTime? requestsCloseAt,  String createdBy,  double? distanceKm)?  $default,) {final _that = this;
switch (_that) {
case _NearbyMatchModel() when $default != null:
return $default(_that.id,_that.venueId,_that.venueName,_that.latitude,_that.longitude,_that.geohashPrefix,_that.format,_that.startTime,_that.openToNearby,_that.slotsNeeded,_that.slotsRemaining,_that.requiredPositions,_that.requestsCloseAt,_that.createdBy,_that.distanceKm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NearbyMatchModel implements NearbyMatchModel {
  const _NearbyMatchModel({@JsonKey(name: '\$id') required this.id, this.venueId, this.venueName, this.latitude, this.longitude, this.geohashPrefix, required this.format, required this.startTime, this.openToNearby = false, this.slotsNeeded = 0, this.slotsRemaining = 0, this.requiredPositions, this.requestsCloseAt, required this.createdBy, this.distanceKm});
  factory _NearbyMatchModel.fromJson(Map<String, dynamic> json) => _$NearbyMatchModelFromJson(json);

@override@JsonKey(name: '\$id') final  String id;
@override final  String? venueId;
@override final  String? venueName;
@override final  double? latitude;
@override final  double? longitude;
@override final  String? geohashPrefix;
@override final  String format;
@override final  DateTime startTime;
@override@JsonKey() final  bool openToNearby;
@override@JsonKey() final  int slotsNeeded;
@override@JsonKey() final  int slotsRemaining;
@override final  String? requiredPositions;
@override final  DateTime? requestsCloseAt;
@override final  String createdBy;
@override final  double? distanceKm;

/// Create a copy of NearbyMatchModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NearbyMatchModelCopyWith<_NearbyMatchModel> get copyWith => __$NearbyMatchModelCopyWithImpl<_NearbyMatchModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NearbyMatchModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NearbyMatchModel&&(identical(other.id, id) || other.id == id)&&(identical(other.venueId, venueId) || other.venueId == venueId)&&(identical(other.venueName, venueName) || other.venueName == venueName)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.geohashPrefix, geohashPrefix) || other.geohashPrefix == geohashPrefix)&&(identical(other.format, format) || other.format == format)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.openToNearby, openToNearby) || other.openToNearby == openToNearby)&&(identical(other.slotsNeeded, slotsNeeded) || other.slotsNeeded == slotsNeeded)&&(identical(other.slotsRemaining, slotsRemaining) || other.slotsRemaining == slotsRemaining)&&(identical(other.requiredPositions, requiredPositions) || other.requiredPositions == requiredPositions)&&(identical(other.requestsCloseAt, requestsCloseAt) || other.requestsCloseAt == requestsCloseAt)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,venueId,venueName,latitude,longitude,geohashPrefix,format,startTime,openToNearby,slotsNeeded,slotsRemaining,requiredPositions,requestsCloseAt,createdBy,distanceKm);

@override
String toString() {
  return 'NearbyMatchModel(id: $id, venueId: $venueId, venueName: $venueName, latitude: $latitude, longitude: $longitude, geohashPrefix: $geohashPrefix, format: $format, startTime: $startTime, openToNearby: $openToNearby, slotsNeeded: $slotsNeeded, slotsRemaining: $slotsRemaining, requiredPositions: $requiredPositions, requestsCloseAt: $requestsCloseAt, createdBy: $createdBy, distanceKm: $distanceKm)';
}


}

/// @nodoc
abstract mixin class _$NearbyMatchModelCopyWith<$Res> implements $NearbyMatchModelCopyWith<$Res> {
  factory _$NearbyMatchModelCopyWith(_NearbyMatchModel value, $Res Function(_NearbyMatchModel) _then) = __$NearbyMatchModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '\$id') String id, String? venueId, String? venueName, double? latitude, double? longitude, String? geohashPrefix, String format, DateTime startTime, bool openToNearby, int slotsNeeded, int slotsRemaining, String? requiredPositions, DateTime? requestsCloseAt, String createdBy, double? distanceKm
});




}
/// @nodoc
class __$NearbyMatchModelCopyWithImpl<$Res>
    implements _$NearbyMatchModelCopyWith<$Res> {
  __$NearbyMatchModelCopyWithImpl(this._self, this._then);

  final _NearbyMatchModel _self;
  final $Res Function(_NearbyMatchModel) _then;

/// Create a copy of NearbyMatchModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? venueId = freezed,Object? venueName = freezed,Object? latitude = freezed,Object? longitude = freezed,Object? geohashPrefix = freezed,Object? format = null,Object? startTime = null,Object? openToNearby = null,Object? slotsNeeded = null,Object? slotsRemaining = null,Object? requiredPositions = freezed,Object? requestsCloseAt = freezed,Object? createdBy = null,Object? distanceKm = freezed,}) {
  return _then(_NearbyMatchModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,venueId: freezed == venueId ? _self.venueId : venueId // ignore: cast_nullable_to_non_nullable
as String?,venueName: freezed == venueName ? _self.venueName : venueName // ignore: cast_nullable_to_non_nullable
as String?,latitude: freezed == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double?,longitude: freezed == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double?,geohashPrefix: freezed == geohashPrefix ? _self.geohashPrefix : geohashPrefix // ignore: cast_nullable_to_non_nullable
as String?,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as DateTime,openToNearby: null == openToNearby ? _self.openToNearby : openToNearby // ignore: cast_nullable_to_non_nullable
as bool,slotsNeeded: null == slotsNeeded ? _self.slotsNeeded : slotsNeeded // ignore: cast_nullable_to_non_nullable
as int,slotsRemaining: null == slotsRemaining ? _self.slotsRemaining : slotsRemaining // ignore: cast_nullable_to_non_nullable
as int,requiredPositions: freezed == requiredPositions ? _self.requiredPositions : requiredPositions // ignore: cast_nullable_to_non_nullable
as String?,requestsCloseAt: freezed == requestsCloseAt ? _self.requestsCloseAt : requestsCloseAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,distanceKm: freezed == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
