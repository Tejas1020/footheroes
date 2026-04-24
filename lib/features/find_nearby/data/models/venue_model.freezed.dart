// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'venue_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VenueModel {

@JsonKey(name: '\$id') String get id; String get name; String? get address; double get latitude; double get longitude; String get geohash; String get createdBy; DateTime get createdAt;
/// Create a copy of VenueModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VenueModelCopyWith<VenueModel> get copyWith => _$VenueModelCopyWithImpl<VenueModel>(this as VenueModel, _$identity);

  /// Serializes this VenueModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VenueModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.geohash, geohash) || other.geohash == geohash)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,address,latitude,longitude,geohash,createdBy,createdAt);

@override
String toString() {
  return 'VenueModel(id: $id, name: $name, address: $address, latitude: $latitude, longitude: $longitude, geohash: $geohash, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $VenueModelCopyWith<$Res>  {
  factory $VenueModelCopyWith(VenueModel value, $Res Function(VenueModel) _then) = _$VenueModelCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: '\$id') String id, String name, String? address, double latitude, double longitude, String geohash, String createdBy, DateTime createdAt
});




}
/// @nodoc
class _$VenueModelCopyWithImpl<$Res>
    implements $VenueModelCopyWith<$Res> {
  _$VenueModelCopyWithImpl(this._self, this._then);

  final VenueModel _self;
  final $Res Function(VenueModel) _then;

/// Create a copy of VenueModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? address = freezed,Object? latitude = null,Object? longitude = null,Object? geohash = null,Object? createdBy = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,geohash: null == geohash ? _self.geohash : geohash // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [VenueModel].
extension VenueModelPatterns on VenueModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _VenueModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _VenueModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _VenueModel value)  $default,){
final _that = this;
switch (_that) {
case _VenueModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _VenueModel value)?  $default,){
final _that = this;
switch (_that) {
case _VenueModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: '\$id')  String id,  String name,  String? address,  double latitude,  double longitude,  String geohash,  String createdBy,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _VenueModel() when $default != null:
return $default(_that.id,_that.name,_that.address,_that.latitude,_that.longitude,_that.geohash,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: '\$id')  String id,  String name,  String? address,  double latitude,  double longitude,  String geohash,  String createdBy,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _VenueModel():
return $default(_that.id,_that.name,_that.address,_that.latitude,_that.longitude,_that.geohash,_that.createdBy,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: '\$id')  String id,  String name,  String? address,  double latitude,  double longitude,  String geohash,  String createdBy,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _VenueModel() when $default != null:
return $default(_that.id,_that.name,_that.address,_that.latitude,_that.longitude,_that.geohash,_that.createdBy,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _VenueModel implements VenueModel {
  const _VenueModel({@JsonKey(name: '\$id') required this.id, required this.name, this.address, required this.latitude, required this.longitude, required this.geohash, required this.createdBy, required this.createdAt});
  factory _VenueModel.fromJson(Map<String, dynamic> json) => _$VenueModelFromJson(json);

@override@JsonKey(name: '\$id') final  String id;
@override final  String name;
@override final  String? address;
@override final  double latitude;
@override final  double longitude;
@override final  String geohash;
@override final  String createdBy;
@override final  DateTime createdAt;

/// Create a copy of VenueModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VenueModelCopyWith<_VenueModel> get copyWith => __$VenueModelCopyWithImpl<_VenueModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VenueModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _VenueModel&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.address, address) || other.address == address)&&(identical(other.latitude, latitude) || other.latitude == latitude)&&(identical(other.longitude, longitude) || other.longitude == longitude)&&(identical(other.geohash, geohash) || other.geohash == geohash)&&(identical(other.createdBy, createdBy) || other.createdBy == createdBy)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,address,latitude,longitude,geohash,createdBy,createdAt);

@override
String toString() {
  return 'VenueModel(id: $id, name: $name, address: $address, latitude: $latitude, longitude: $longitude, geohash: $geohash, createdBy: $createdBy, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$VenueModelCopyWith<$Res> implements $VenueModelCopyWith<$Res> {
  factory _$VenueModelCopyWith(_VenueModel value, $Res Function(_VenueModel) _then) = __$VenueModelCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: '\$id') String id, String name, String? address, double latitude, double longitude, String geohash, String createdBy, DateTime createdAt
});




}
/// @nodoc
class __$VenueModelCopyWithImpl<$Res>
    implements _$VenueModelCopyWith<$Res> {
  __$VenueModelCopyWithImpl(this._self, this._then);

  final _VenueModel _self;
  final $Res Function(_VenueModel) _then;

/// Create a copy of VenueModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? address = freezed,Object? latitude = null,Object? longitude = null,Object? geohash = null,Object? createdBy = null,Object? createdAt = null,}) {
  return _then(_VenueModel(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String?,latitude: null == latitude ? _self.latitude : latitude // ignore: cast_nullable_to_non_nullable
as double,longitude: null == longitude ? _self.longitude : longitude // ignore: cast_nullable_to_non_nullable
as double,geohash: null == geohash ? _self.geohash : geohash // ignore: cast_nullable_to_non_nullable
as String,createdBy: null == createdBy ? _self.createdBy : createdBy // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
