// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_bike.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$currentBikeHash() => r'47d93bef4d349bc5026dc3903499136509807f11';

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
String _$savedBikeListHash() => r'd0c9ae062100d0d96e4aab5d3afd9215cce907dc';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
