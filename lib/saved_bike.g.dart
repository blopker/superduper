// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_bike.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentBikeHash() => r'5e401c4c413ca54684ab281472d709fb4e3dd5a4';

/// See also [currentBike].
@ProviderFor(currentBike)
final currentBikeProvider = AutoDisposeProvider<BikeState?>.internal(
  currentBike,
  name: r'currentBikeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentBikeHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef CurrentBikeRef = AutoDisposeProviderRef<BikeState?>;
String _$savedBikeListHash() => r'018e5515aa1dba5c93b9269f118431af8c79d988';

/// See also [SavedBikeList].
@ProviderFor(SavedBikeList)
final savedBikeListProvider =
    AutoDisposeNotifierProvider<SavedBikeList, List<BikeState>>.internal(
  SavedBikeList.new,
  name: r'savedBikeListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$savedBikeListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$SavedBikeList = AutoDisposeNotifier<List<BikeState>>;
// ignore_for_file: unnecessary_raw_strings, subtype_of_sealed_class, invalid_use_of_internal_member, do_not_use_environment, prefer_const_constructors, public_member_api_docs, avoid_private_typedef_functions
