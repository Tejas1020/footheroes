// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'join_requests_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$matchJoinRequestsNotifierHash() =>
    r'2a51657b65e71a8d82bb0bbc8ce25de5bdfff420';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$MatchJoinRequestsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<JoinRequest>> {
  late final String matchId;

  FutureOr<List<JoinRequest>> build(String matchId);
}

/// See also [MatchJoinRequestsNotifier].
@ProviderFor(MatchJoinRequestsNotifier)
const matchJoinRequestsNotifierProvider = MatchJoinRequestsNotifierFamily();

/// See also [MatchJoinRequestsNotifier].
class MatchJoinRequestsNotifierFamily
    extends Family<AsyncValue<List<JoinRequest>>> {
  /// See also [MatchJoinRequestsNotifier].
  const MatchJoinRequestsNotifierFamily();

  /// See also [MatchJoinRequestsNotifier].
  MatchJoinRequestsNotifierProvider call(String matchId) {
    return MatchJoinRequestsNotifierProvider(matchId);
  }

  @override
  MatchJoinRequestsNotifierProvider getProviderOverride(
    covariant MatchJoinRequestsNotifierProvider provider,
  ) {
    return call(provider.matchId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'matchJoinRequestsNotifierProvider';
}

/// See also [MatchJoinRequestsNotifier].
class MatchJoinRequestsNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          MatchJoinRequestsNotifier,
          List<JoinRequest>
        > {
  /// See also [MatchJoinRequestsNotifier].
  MatchJoinRequestsNotifierProvider(String matchId)
    : this._internal(
        () => MatchJoinRequestsNotifier()..matchId = matchId,
        from: matchJoinRequestsNotifierProvider,
        name: r'matchJoinRequestsNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$matchJoinRequestsNotifierHash,
        dependencies: MatchJoinRequestsNotifierFamily._dependencies,
        allTransitiveDependencies:
            MatchJoinRequestsNotifierFamily._allTransitiveDependencies,
        matchId: matchId,
      );

  MatchJoinRequestsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.matchId,
  }) : super.internal();

  final String matchId;

  @override
  FutureOr<List<JoinRequest>> runNotifierBuild(
    covariant MatchJoinRequestsNotifier notifier,
  ) {
    return notifier.build(matchId);
  }

  @override
  Override overrideWith(MatchJoinRequestsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: MatchJoinRequestsNotifierProvider._internal(
        () => create()..matchId = matchId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        matchId: matchId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    MatchJoinRequestsNotifier,
    List<JoinRequest>
  >
  createElement() {
    return _MatchJoinRequestsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MatchJoinRequestsNotifierProvider &&
        other.matchId == matchId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, matchId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MatchJoinRequestsNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<JoinRequest>> {
  /// The parameter `matchId` of this provider.
  String get matchId;
}

class _MatchJoinRequestsNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          MatchJoinRequestsNotifier,
          List<JoinRequest>
        >
    with MatchJoinRequestsNotifierRef {
  _MatchJoinRequestsNotifierProviderElement(super.provider);

  @override
  String get matchId => (origin as MatchJoinRequestsNotifierProvider).matchId;
}

String _$myJoinRequestsNotifierHash() =>
    r'37b99e5eadf5bae7b6c15328824fb0c8a5188e3e';

abstract class _$MyJoinRequestsNotifier
    extends BuildlessAutoDisposeAsyncNotifier<List<JoinRequest>> {
  late final String requesterUid;

  FutureOr<List<JoinRequest>> build(String requesterUid);
}

/// See also [MyJoinRequestsNotifier].
@ProviderFor(MyJoinRequestsNotifier)
const myJoinRequestsNotifierProvider = MyJoinRequestsNotifierFamily();

/// See also [MyJoinRequestsNotifier].
class MyJoinRequestsNotifierFamily
    extends Family<AsyncValue<List<JoinRequest>>> {
  /// See also [MyJoinRequestsNotifier].
  const MyJoinRequestsNotifierFamily();

  /// See also [MyJoinRequestsNotifier].
  MyJoinRequestsNotifierProvider call(String requesterUid) {
    return MyJoinRequestsNotifierProvider(requesterUid);
  }

  @override
  MyJoinRequestsNotifierProvider getProviderOverride(
    covariant MyJoinRequestsNotifierProvider provider,
  ) {
    return call(provider.requesterUid);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'myJoinRequestsNotifierProvider';
}

/// See also [MyJoinRequestsNotifier].
class MyJoinRequestsNotifierProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          MyJoinRequestsNotifier,
          List<JoinRequest>
        > {
  /// See also [MyJoinRequestsNotifier].
  MyJoinRequestsNotifierProvider(String requesterUid)
    : this._internal(
        () => MyJoinRequestsNotifier()..requesterUid = requesterUid,
        from: myJoinRequestsNotifierProvider,
        name: r'myJoinRequestsNotifierProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$myJoinRequestsNotifierHash,
        dependencies: MyJoinRequestsNotifierFamily._dependencies,
        allTransitiveDependencies:
            MyJoinRequestsNotifierFamily._allTransitiveDependencies,
        requesterUid: requesterUid,
      );

  MyJoinRequestsNotifierProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.requesterUid,
  }) : super.internal();

  final String requesterUid;

  @override
  FutureOr<List<JoinRequest>> runNotifierBuild(
    covariant MyJoinRequestsNotifier notifier,
  ) {
    return notifier.build(requesterUid);
  }

  @override
  Override overrideWith(MyJoinRequestsNotifier Function() create) {
    return ProviderOverride(
      origin: this,
      override: MyJoinRequestsNotifierProvider._internal(
        () => create()..requesterUid = requesterUid,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        requesterUid: requesterUid,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    MyJoinRequestsNotifier,
    List<JoinRequest>
  >
  createElement() {
    return _MyJoinRequestsNotifierProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is MyJoinRequestsNotifierProvider &&
        other.requesterUid == requesterUid;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, requesterUid.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin MyJoinRequestsNotifierRef
    on AutoDisposeAsyncNotifierProviderRef<List<JoinRequest>> {
  /// The parameter `requesterUid` of this provider.
  String get requesterUid;
}

class _MyJoinRequestsNotifierProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          MyJoinRequestsNotifier,
          List<JoinRequest>
        >
    with MyJoinRequestsNotifierRef {
  _MyJoinRequestsNotifierProviderElement(super.provider);

  @override
  String get requesterUid =>
      (origin as MyJoinRequestsNotifierProvider).requesterUid;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
