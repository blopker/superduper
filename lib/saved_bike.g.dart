// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_bike.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// ignore_for_file: avoid_private_typedef_functions, non_constant_identifier_names, subtype_of_sealed_class, invalid_use_of_internal_member, unused_element, constant_identifier_names, unnecessary_raw_strings, library_private_types_in_public_api

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

String _$SavedBikeListHash() => r'1410728375729163c1713b58dde4aca32dc8bf47';

/// See also [SavedBikeList].
final savedBikeListProvider =
    AutoDisposeNotifierProvider<SavedBikeList, List<BikeState>>(
  SavedBikeList.new,
  name: r'savedBikeListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$SavedBikeListHash,
);
typedef SavedBikeListRef = AutoDisposeNotifierProviderRef<List<BikeState>>;

abstract class _$SavedBikeList extends AutoDisposeNotifier<List<BikeState>> {
  @override
  List<BikeState> build();
}

String _$currentBikeHash() => r'e6582f7a975d17b943fd5c8a0027a60b5a372188';

/// See also [currentBike].
final currentBikeProvider = AutoDisposeProvider<BikeState?>(
  currentBike,
  name: r'currentBikeProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$currentBikeHash,
);
typedef CurrentBikeRef = AutoDisposeProviderRef<BikeState?>;
