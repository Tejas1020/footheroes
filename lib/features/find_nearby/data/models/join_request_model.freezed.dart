// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'join_request_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$JoinRequestModel {

@JsonKey(name: '\$id') String get id; String get matchId; String get requesterUid; String get requesterPosition; String? get requesterMessage; String get status; String? get assignedSide; DateTime get createdAt; DateTime? get respondedAt;
/// Create a copy of JoinRequestModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$JoinRequestModelCopyWith<JoinRequestModel> get copyWith => _$JoinRequestModelCopyWithImpl<JoinRequestModel>(this as JoinRequestModel, _$identity);

  /// Serializes this JoinRequestModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is JoinRequestModel&&(identical(other.id, id) || other.id == id)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.requesterUid, requesterUid) || other.requesterUid == requesterUid)&&(identical(other.requesterPosition, requesterPosition) || other.requesterPosition == requesterPosition)&&(identical(other.requesterMessage, requesterMessage) || other.requesterMessage == requesterMessage)&&(identical(other.status, status) || other.status == status)&&(identical(other.assignedSide, assignedSide) || other.assignedSide == assignedSide)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,matchId,requesterUid,requesterPosition,requesterMessage,status,assignedSide,createdAt,respondedAt);

@override
String toString() {
  return 'JoinRequestModel(id: $id, matchId: $matchId, requesterUid: $requesterUid, requesterPosition: $requesterPosition, requesterMessage: $requesterMessage, status: $status, assignedSide: $assignedSide, createdAt: $createdAt, respondedAt: $respondedAt)';
}


}

/// @nodoc
abstract mixin class $JoinRequestModelCopyWith<$Res>  {
  factory $JoinRequestModelCopyWith(JoinRequestModel value, $Res Function(JoinRequestModel) _then) = _$JoinRequestModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '\$id') String id, String matchId, String requesterUid, String requesterPosition, String? requesterMessage, String status, String? assignedSide, DateTime createdAt, DateTime? respondedAt
});




}
/// @nodoc
class _$JoinRequestModelCopyWithImpl<$Res>
    implements $JoinRequestModelCopyWith<$Res> {
  _$JoinRequestModelCopyWithImpl(this._self, this._then);

  final JoinRequestModel _self;
  final $Res Function(JoinRequestModel) _then;

/// Create a copy of JoinRequestModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? matchId = null,Object? requesterUid = null,Object? requesterPosition = null,Object? requesterMessage = freezed,Object? status = null,Object? assignedSide = freezed,Object? createdAt = null,Object? respondedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,requesterUid: null == requesterUid ? _self.requesterUid : requesterUid // ignore: cast_nullable_to_non_nullable
as String,requesterPosition: null == requesterPosition ? _self.requesterPosition : requesterPosition // ignore: cast_nullable_to_non_nullable
as String,requesterMessage: freezed == requesterMessage ? _self.requesterMessage : requesterMessage // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,assignedSide: freezed == assignedSide ? _self.assignedSide : assignedSide // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [JoinRequestModel].
extension JoinRequestModelPatterns on JoinRequestModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _JoinRequestModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _JoinRequestModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _JoinRequestModel value)  $default,){
final _that = this;
switch (_that) {
case _JoinRequestModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _JoinRequestModel value)?  $default,){
final _that = this;
switch (_that) {
case _JoinRequestModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '\$id')  String id,  String matchId,  String requesterUid,  String requesterPosition,  String? requesterMessage,  String status,  String? assignedSide,  DateTime createdAt,  DateTime? respondedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _JoinRequestModel() when $default != null:
return $default(_that.id,_that.matchId,_that.requesterUid,_that.requesterPosition,_that.requesterMessage,_that.status,_that.assignedSide,_that.createdAt,_that.respondedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '\$id')  String id,  String matchId,  String requesterUid,  String requesterPosition,  String? requesterMessage,  String status,  String? assignedSide,  DateTime createdAt,  DateTime? respondedAt)  $default,) {final _that = this;
switch (_that) {
case _JoinRequestModel():
return $default(_that.id,_that.matchId,_that.requesterUid,_that.requesterPosition,_that.requesterMessage,_that.status,_that.assignedSide,_that.createdAt,_that.respondedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '\$id')  String id,  String matchId,  String requesterUid,  String requesterPosition,  String? requesterMessage,  String status,  String? assignedSide,  DateTime createdAt,  DateTime? respondedAt)?  $default,) {final _that = this;
switch (_that) {
case _JoinRequestModel() when $default != null:
return $default(_that.id,_that.matchId,_that.requesterUid,_that.requesterPosition,_that.requesterMessage,_that.status,_that.assignedSide,_that.createdAt,_that.respondedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _JoinRequestModel implements JoinRequestModel {
  const _JoinRequestModel({@JsonKey(name: '\$id') required this.id, required this.matchId, required this.requesterUid, required this.requesterPosition, this.requesterMessage, required this.status, this.assignedSide, required this.createdAt, this.respondedAt});
  factory _JoinRequestModel.fromJson(Map<String, dynamic> json) => _$JoinRequestModelFromJson(json);

@override@JsonKey(name: '\$id') final  String id;
@override final  String matchId;
@override final  String requesterUid;
@override final  String requesterPosition;
@override final  String? requesterMessage;
@override final  String status;
@override final  String? assignedSide;
@override final  DateTime createdAt;
@override final  DateTime? respondedAt;

/// Create a copy of JoinRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$JoinRequestModelCopyWith<_JoinRequestModel> get copyWith => __$JoinRequestModelCopyWithImpl<_JoinRequestModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$JoinRequestModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _JoinRequestModel&&(identical(other.id, id) || other.id == id)&&(identical(other.matchId, matchId) || other.matchId == matchId)&&(identical(other.requesterUid, requesterUid) || other.requesterUid == requesterUid)&&(identical(other.requesterPosition, requesterPosition) || other.requesterPosition == requesterPosition)&&(identical(other.requesterMessage, requesterMessage) || other.requesterMessage == requesterMessage)&&(identical(other.status, status) || other.status == status)&&(identical(other.assignedSide, assignedSide) || other.assignedSide == assignedSide)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.respondedAt, respondedAt) || other.respondedAt == respondedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,matchId,requesterUid,requesterPosition,requesterMessage,status,assignedSide,createdAt,respondedAt);

@override
String toString() {
  return 'JoinRequestModel(id: $id, matchId: $matchId, requesterUid: $requesterUid, requesterPosition: $requesterPosition, requesterMessage: $requesterMessage, status: $status, assignedSide: $assignedSide, createdAt: $createdAt, respondedAt: $respondedAt)';
}


}

/// @nodoc
abstract mixin class _$JoinRequestModelCopyWith<$Res> implements $JoinRequestModelCopyWith<$Res> {
  factory _$JoinRequestModelCopyWith(_JoinRequestModel value, $Res Function(_JoinRequestModel) _then) = __$JoinRequestModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '\$id') String id, String matchId, String requesterUid, String requesterPosition, String? requesterMessage, String status, String? assignedSide, DateTime createdAt, DateTime? respondedAt
});




}
/// @nodoc
class __$JoinRequestModelCopyWithImpl<$Res>
    implements _$JoinRequestModelCopyWith<$Res> {
  __$JoinRequestModelCopyWithImpl(this._self, this._then);

  final _JoinRequestModel _self;
  final $Res Function(_JoinRequestModel) _then;

/// Create a copy of JoinRequestModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? matchId = null,Object? requesterUid = null,Object? requesterPosition = null,Object? requesterMessage = freezed,Object? status = null,Object? assignedSide = freezed,Object? createdAt = null,Object? respondedAt = freezed,}) {
  return _then(_JoinRequestModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,matchId: null == matchId ? _self.matchId : matchId // ignore: cast_nullable_to_non_nullable
as String,requesterUid: null == requesterUid ? _self.requesterUid : requesterUid // ignore: cast_nullable_to_non_nullable
as String,requesterPosition: null == requesterPosition ? _self.requesterPosition : requesterPosition // ignore: cast_nullable_to_non_nullable
as String,requesterMessage: freezed == requesterMessage ? _self.requesterMessage : requesterMessage // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,assignedSide: freezed == assignedSide ? _self.assignedSide : assignedSide // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,respondedAt: freezed == respondedAt ? _self.respondedAt : respondedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
