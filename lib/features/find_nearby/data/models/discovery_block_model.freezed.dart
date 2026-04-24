// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'discovery_block_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DiscoveryBlockModel {

@JsonKey(name: '\$id') String get id; String get creatorUid; String get playerUid; DateTime get createdAt;
/// Create a copy of DiscoveryBlockModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DiscoveryBlockModelCopyWith<DiscoveryBlockModel> get copyWith => _$DiscoveryBlockModelCopyWithImpl<DiscoveryBlockModel>(this as DiscoveryBlockModel, _$identity);

  /// Serializes this DiscoveryBlockModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DiscoveryBlockModel&&(identical(other.id, id) || other.id == id)&&(identical(other.creatorUid, creatorUid) || other.creatorUid == creatorUid)&&(identical(other.playerUid, playerUid) || other.playerUid == playerUid)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,creatorUid,playerUid,createdAt);

@override
String toString() {
  return 'DiscoveryBlockModel(id: $id, creatorUid: $creatorUid, playerUid: $playerUid, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $DiscoveryBlockModelCopyWith<$Res>  {
  factory $DiscoveryBlockModelCopyWith(DiscoveryBlockModel value, $Res Function(DiscoveryBlockModel) _then) = _$DiscoveryBlockModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '\$id') String id, String creatorUid, String playerUid, DateTime createdAt
});




}
/// @nodoc
class _$DiscoveryBlockModelCopyWithImpl<$Res>
    implements $DiscoveryBlockModelCopyWith<$Res> {
  _$DiscoveryBlockModelCopyWithImpl(this._self, this._then);

  final DiscoveryBlockModel _self;
  final $Res Function(DiscoveryBlockModel) _then;

/// Create a copy of DiscoveryBlockModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? creatorUid = null,Object? playerUid = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,creatorUid: null == creatorUid ? _self.creatorUid : creatorUid // ignore: cast_nullable_to_non_nullable
as String,playerUid: null == playerUid ? _self.playerUid : playerUid // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [DiscoveryBlockModel].
extension DiscoveryBlockModelPatterns on DiscoveryBlockModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DiscoveryBlockModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DiscoveryBlockModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DiscoveryBlockModel value)  $default,){
final _that = this;
switch (_that) {
case _DiscoveryBlockModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DiscoveryBlockModel value)?  $default,){
final _that = this;
switch (_that) {
case _DiscoveryBlockModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '\$id')  String id,  String creatorUid,  String playerUid,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DiscoveryBlockModel() when $default != null:
return $default(_that.id,_that.creatorUid,_that.playerUid,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '\$id')  String id,  String creatorUid,  String playerUid,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _DiscoveryBlockModel():
return $default(_that.id,_that.creatorUid,_that.playerUid,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '\$id')  String id,  String creatorUid,  String playerUid,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _DiscoveryBlockModel() when $default != null:
return $default(_that.id,_that.creatorUid,_that.playerUid,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DiscoveryBlockModel implements DiscoveryBlockModel {
  const _DiscoveryBlockModel({@JsonKey(name: '\$id') required this.id, required this.creatorUid, required this.playerUid, required this.createdAt});
  factory _DiscoveryBlockModel.fromJson(Map<String, dynamic> json) => _$DiscoveryBlockModelFromJson(json);

@override@JsonKey(name: '\$id') final  String id;
@override final  String creatorUid;
@override final  String playerUid;
@override final  DateTime createdAt;

/// Create a copy of DiscoveryBlockModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DiscoveryBlockModelCopyWith<_DiscoveryBlockModel> get copyWith => __$DiscoveryBlockModelCopyWithImpl<_DiscoveryBlockModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DiscoveryBlockModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DiscoveryBlockModel&&(identical(other.id, id) || other.id == id)&&(identical(other.creatorUid, creatorUid) || other.creatorUid == creatorUid)&&(identical(other.playerUid, playerUid) || other.playerUid == playerUid)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,creatorUid,playerUid,createdAt);

@override
String toString() {
  return 'DiscoveryBlockModel(id: $id, creatorUid: $creatorUid, playerUid: $playerUid, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$DiscoveryBlockModelCopyWith<$Res> implements $DiscoveryBlockModelCopyWith<$Res> {
  factory _$DiscoveryBlockModelCopyWith(_DiscoveryBlockModel value, $Res Function(_DiscoveryBlockModel) _then) = __$DiscoveryBlockModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '\$id') String id, String creatorUid, String playerUid, DateTime createdAt
});




}
/// @nodoc
class __$DiscoveryBlockModelCopyWithImpl<$Res>
    implements _$DiscoveryBlockModelCopyWith<$Res> {
  __$DiscoveryBlockModelCopyWithImpl(this._self, this._then);

  final _DiscoveryBlockModel _self;
  final $Res Function(_DiscoveryBlockModel) _then;

/// Create a copy of DiscoveryBlockModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? creatorUid = null,Object? playerUid = null,Object? createdAt = null,}) {
  return _then(_DiscoveryBlockModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,creatorUid: null == creatorUid ? _self.creatorUid : creatorUid // ignore: cast_nullable_to_non_nullable
as String,playerUid: null == playerUid ? _self.playerUid : playerUid // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
